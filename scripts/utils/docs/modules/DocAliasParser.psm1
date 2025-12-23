<#
scripts/utils/docs/modules/DocAliasParser.psm1

.SYNOPSIS
    Alias parsing utilities for documentation extraction.

.DESCRIPTION
    Provides functions for detecting and parsing aliases from PowerShell files.
#>

# Import regex patterns
$regexModulePath = Join-Path $PSScriptRoot 'DocParserRegex.psm1'
if (Test-Path $regexModulePath) {
    Import-Module $regexModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Try to import Collections and FileContent modules from scripts/lib (optional)
$libPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)))) 'lib'
$collectionsModulePath = Join-Path $libPath 'Collections.psm1'
$fileContentModulePath = Join-Path $libPath 'FileContent.psm1'
if (Test-Path $collectionsModulePath) {
    Import-Module $collectionsModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
if (Test-Path $fileContentModulePath) {
    Import-Module $fileContentModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Parses aliases from a PowerShell file.

.DESCRIPTION
    Detects Set-Alias and Set-AgentModeAlias calls and extracts their documentation.

.PARAMETER File
    Path to the PowerShell file to parse.

.PARAMETER Functions
    List of already-parsed functions (used to find target function descriptions).

.OUTPUTS
    List of PSCustomObject with alias information.
#>
function Get-CommandParameterValue {
    param(
        [System.Management.Automation.Language.CommandAst]$CommandAst,
        [string]$ParameterName
    )

    if (-not $CommandAst -or -not $ParameterName) {
        return $null
    }

    $elements = $CommandAst.CommandElements
    for ($i = 0; $i -lt $elements.Count; $i++) {
        $element = $elements[$i]
        if ($element -is [System.Management.Automation.Language.CommandParameterAst] -and $element.ParameterName -ieq $ParameterName) {
            if ($element.Argument) {
                try {
                    $value = $element.Argument.SafeGetValue()
                    if ($null -ne $value) {
                        return $value
                    }
                }
                catch {
                    # If SafeGetValue fails, try to extract string literal
                    if ($element.Argument -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                        return $element.Argument.Value
                    }
                }
            }
            elseif ($i + 1 -lt $elements.Count) {
                $next = $elements[$i + 1]
                if ($next -is [System.Management.Automation.Language.ExpressionAst]) {
                    try {
                        $value = $next.SafeGetValue()
                        if ($null -ne $value) {
                            return $value
                        }
                    }
                    catch {
                        # If SafeGetValue fails, try to extract string literal
                        if ($next -is [System.Management.Automation.Language.StringConstantExpressionAst]) {
                            return $next.Value
                        }
                    }
                }
            }
        }
    }

    return $null
}

function Parse-AliasesFromFile {
    [CmdletBinding()]
    [OutputType([System.Collections.Generic.List[PSCustomObject]])]
    param(
        [Parameter(Mandatory)]
        [string]$File,

        [Parameter(Mandatory)]
        [AllowEmptyCollection()]
        [System.Collections.Generic.List[PSCustomObject]]$Functions
    )

    if (Get-Command New-ObjectList -ErrorAction SilentlyContinue) {
        $aliases = New-ObjectList
    }
    else {
        $aliases = [System.Collections.Generic.List[PSCustomObject]]::new()
    }
    
    # Ensure $aliases is never null
    if (-not $aliases) {
        $aliases = [System.Collections.Generic.List[PSCustomObject]]::new()
    }

    # Use FileContent module if available, otherwise fallback
    if (Get-Command Read-FileContent -ErrorAction SilentlyContinue) {
        $allLines = Read-FileContent -Path $File
    }
    else {
        $allLines = Get-Content $File -Raw -ErrorAction SilentlyContinue
    }
    if (-not $allLines) {
        return $aliases
    }

    $lines = $allLines -split "`r?`n"

    $parseErrors = $null
    $tokens = $null
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($File, [ref]$tokens, [ref]$parseErrors)
    if (-not $ast) {
        return $aliases
    }

    $aliasCommands = $ast.FindAll({
            param($node)
            if ($node -isnot [System.Management.Automation.Language.CommandAst]) { return $false }
            $cmdName = $node.GetCommandName()
            return $cmdName -and ($cmdName -ieq 'Set-Alias' -or $cmdName -ieq 'Set-AgentModeAlias')
        }, $true)

    if ($env:PS_PROFILE_DEBUG -eq '1') {
        Write-Host "[AliasParser] $File -> $($aliasCommands.Count) alias command(s)" -ForegroundColor DarkCyan
    }

    foreach ($commandAst in $aliasCommands) {
        $commandName = $commandAst.GetCommandName()
        $aliasName = Get-CommandParameterValue -CommandAst $commandAst -ParameterName 'Name'
        $targetParam = if ($commandName -ieq 'Set-AgentModeAlias') { 'Target' } else { 'Value' }
        $targetCommand = Get-CommandParameterValue -CommandAst $commandAst -ParameterName $targetParam

        # Convert to string and trim quotes if present
        if ($aliasName) {
            $aliasName = $aliasName.ToString().Trim('"', "'")
        }
        if ($targetCommand) {
            $targetCommand = $targetCommand.ToString().Trim('"', "'")
        }

        if (-not $aliasName -or -not $targetCommand) {
            if ($env:PS_PROFILE_DEBUG -eq '1') {
                Write-Host "[AliasParser] Skipping alias - Name: '$aliasName', Target: '$targetCommand'" -ForegroundColor DarkYellow
            }
            continue
        }

        if ($env:PS_PROFILE_DEBUG -eq '1') {
            Write-Host "[AliasParser] Found alias: $aliasName -> $targetCommand" -ForegroundColor DarkGreen
        }

        try {
            # Look for comment block before alias (within 30 lines)
            $aliasLineIndex = $commandAst.Extent.StartLineNumber - 1
            $helpContent = ""
            if ($aliasLineIndex -gt 0) {
                $startIdx = [Math]::Max(0, $aliasLineIndex - 30)
                $beforeLines = $lines[$startIdx..($aliasLineIndex - 1)]
                $beforeText = $beforeLines -join "`n"
            
                # Use regex module if available, otherwise use simple pattern
                if ($script:regexCommentBlock) {
                    $commentMatches = $script:regexCommentBlock.Matches($beforeText)
                }
                else {
                    # Fallback: simple regex pattern
                    $commentMatches = [regex]::Matches($beforeText, '<#[\s\S]*?#>')
                }
            
                if ($commentMatches -and $commentMatches.Count -gt 0) {
                    $helpContent = $commentMatches[-1].Value
                    $helpContent = $helpContent -replace '^<#\s*', '' -replace '\s*#>$', ''
                    $helpContent = $helpContent.Trim()

                    $helpLines = $helpContent -split "`r?\n"
                    $nonEmptyLines = $helpLines | Where-Object { $_ -match '\S' }
                    if ($nonEmptyLines) {
                        $minIndent = ($nonEmptyLines | ForEach-Object { ($_.Length - $_.TrimStart().Length) } | Measure-Object -Minimum).Minimum
                        if ($minIndent -gt 0) {
                            $helpLines = $helpLines | ForEach-Object { if ($_.Length -ge $minIndent) { $_.Substring($minIndent) } else { $_ } }
                        }
                    }
                    $helpContent = $helpLines -join "`n"
                }
            }

            $synopsis = ""
            $description = ""
            if ($helpContent) {
                $synopsisMatch = $helpContent -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.(?:DESCRIPTION|PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)'
                if ($synopsisMatch -and
                    $matches -and
                    $matches.Count -gt 1 -and
                    $matches[1]) {
                    $synopsis = $matches[1].Trim() -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
                }

                $descMatch = $helpContent -match '(?s)\.DESCRIPTION\s*\n\s*(.+?)(?=\n\s*\.(?:PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)'
                if ($descMatch -and
                    $matches -and
                    $matches.Count -gt 1 -and
                    $matches[1]) {
                    $description = $matches[1].Trim() -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
                }

                if (-not $synopsis -and -not $description) {
                    foreach ($helpLine in $helpContent -split "`r?\n") {
                        if (-not $helpLine) { continue }
                        $trimmed = $helpLine.Trim()
                        if ($trimmed -and
                            $trimmed -notmatch '^\.(SYNOPSIS|DESCRIPTION|PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)' -and
                            $trimmed -notmatch '^[-=\s]*$' -and
                            $trimmed.Length -lt 200) {
                            $synopsis = $trimmed
                            break
                        }
                    }
                }
            }

            # If no synopsis found, try to get it from the target function
            if (-not $synopsis) {
                $targetFunc = $Functions | Where-Object { $_.Name -eq $targetCommand } | Select-Object -First 1
                if ($targetFunc) {
                    if ($targetFunc.Synopsis) {
                        $synopsis = $targetFunc.Synopsis
                    }
                    if (-not $description -and $targetFunc.Description) {
                        $description = $targetFunc.Description
                    }
                }
            }

            # If still no synopsis, create a default one
            if (-not $synopsis) {
                $synopsis = "Alias for ``$targetCommand``"
            }

            $aliases.Add([PSCustomObject]@{
                    Name        = if ($aliasName) { $aliasName.ToString() } else { "" }
                    Target      = if ($targetCommand) { $targetCommand.ToString() } else { "" }
                    Synopsis    = if ($synopsis) { $synopsis } else { "" }
                    Description = if ($description) { $description } else { "" }
                    File        = if ($File) { $File } else { "" }
                })
        }
        catch {
            Write-Warning "Error processing alias $aliasName -> $targetCommand : $($_.Exception.Message)"
            Write-Warning "Error at line: $($_.InvocationInfo.ScriptLineNumber)"
            Write-Warning "AliasName type: $($aliasName.GetType().FullName), Value: '$aliasName'"
            Write-Warning "TargetCommand type: $($targetCommand.GetType().FullName), Value: '$targetCommand'"
            Write-Warning "Aliases list is null: $($null -eq $aliases)"
            if ($aliases) {
                Write-Warning "Aliases list type: $($aliases.GetType().FullName), Count: $($aliases.Count)"
            }
        }
    }

    return $aliases
}

Export-ModuleMember -Function Parse-AliasesFromFile

