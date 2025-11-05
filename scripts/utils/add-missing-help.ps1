<#
scripts/utils/add-missing-help.ps1

Adds missing .SYNOPSIS and .DESCRIPTION sections to comment-based help blocks.
#>

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$profilePath = Join-Path $repoRoot 'profile.d'

Write-Output "Scanning for functions and aliases missing Synopsis/Description..."

$filesToUpdate = @()

Get-ChildItem -Path $profilePath -Filter '*.ps1' | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw
    $lines = $content -split "`r?`n"
    
    # Parse the file content to find functions using AST
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
    $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    
    foreach ($funcAst in $functionAsts) {
        $functionName = $funcAst.Name
        
        # Skip functions with colons (like global:..) as they are internal aliases
        if ($functionName -match ':') {
            continue
        }
        
        $start = $funcAst.Extent.StartOffset
        $beforeText = $content.Substring(0, $start)
        
        # Find the last comment block before the function
        $commentMatches = [regex]::Matches($beforeText, '<#[\s\S]*?#>')
        if ($commentMatches.Count -gt 0) {
            $helpContent = $commentMatches[-1].Value
            $helpText = $helpContent -replace '^<#\s*', '' -replace '\s*#>$', ''
            $helpText = $helpText.Trim()
            
            # Check if SYNOPSIS or DESCRIPTION are missing
            $hasSynopsis = $helpText -match '(?s)\.SYNOPSIS'
            $hasDescription = $helpText -match '(?s)\.DESCRIPTION'
            
            if (-not $hasSynopsis -or -not $hasDescription) {
                $commentStart = $commentMatches[-1].Index
                $commentEnd = $commentStart + $commentMatches[-1].Length
                
                $filesToUpdate += [PSCustomObject]@{
                    File           = $file
                    FunctionName   = $functionName
                    CommentStart   = $commentStart
                    CommentEnd     = $commentEnd
                    HelpText       = $helpText
                    HasSynopsis    = $hasSynopsis
                    HasDescription = $hasDescription
                    LineNumber     = ($content.Substring(0, $start) -split "`r?`n").Count
                }
            }
        }
    }
    
    # Also check for aliases with comment blocks
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        $aliasName = $null
        $targetCommand = $null
        
        # Match Set-Alias patterns
        if ($line -match 'Set-Alias\s+-Name\s+([A-Za-z0-9_\-]+)\s+-Value\s+([A-Za-z0-9_\-\.\~]+)') {
            $aliasName = $matches[1]
            $targetCommand = $matches[2]
        }
        elseif ($line -match 'Set-AgentModeAlias\s+-Name\s+[\x27\x22]([A-Za-z0-9_\-]+)[\x27\x22]\s+-Target\s+[\x27\x22]?([A-Za-z0-9_\-\.\~]+)') {
            $aliasName = $matches[1]
            $targetCommand = $matches[2]
        }
        elseif ($line -match 'Set-Alias\s+-Name\s+([A-Za-z0-9_\-]+)') {
            $aliasName = $matches[1]
            for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $lines.Count); $j++) {
                $nextLine = $lines[$j].Trim()
                if ($nextLine -match '-Value\s+([A-Za-z0-9_\-\.\~]+)') {
                    $targetCommand = $matches[1]
                    break
                }
                if ($nextLine -match '^\s*$' -or $nextLine -match '^\s*[A-Za-z]') {
                    break
                }
            }
        }
        
        if ($aliasName -and $targetCommand) {
            # Look for comment block before the alias (up to 30 lines back)
            $beforeText = ""
            if ($i -gt 0) {
                $startIdx = [Math]::Max(0, $i - 30)
                $beforeText = ($lines[$startIdx..($i - 1)] -join "`n")
            }
            
            $commentMatches = [regex]::Matches($beforeText, '<#[\s\S]*?#>')
            if ($commentMatches.Count -gt 0) {
                $helpContent = $commentMatches[-1].Value
                $helpText = $helpContent -replace '^<#\s*', '' -replace '\s*#>$', ''
                $helpText = $helpText.Trim()
                
                $hasSynopsis = $helpText -match '(?s)\.SYNOPSIS'
                $hasDescription = $helpText -match '(?s)\.DESCRIPTION'
                
                if (-not $hasSynopsis -or -not $hasDescription) {
                    $filesToUpdate += [PSCustomObject]@{
                        File           = $file
                        AliasName      = $aliasName
                        TargetCommand  = $targetCommand
                        HelpText       = $helpText
                        HasSynopsis    = $hasSynopsis
                        HasDescription = $hasDescription
                        LineNumber     = $i + 1
                    }
                }
            }
        }
    }
}

Write-Output "Found $($filesToUpdate.Count) functions/aliases missing Synopsis or Description"

if ($filesToUpdate.Count -eq 0) {
    Write-Output "All comment blocks have Synopsis and Description. Nothing to update."
    exit 0
}

# Group by file for easier processing
$groupedByFile = $filesToUpdate | Group-Object File

foreach ($group in $groupedByFile) {
    $file = $group.Name
    Write-Output "`nProcessing $file..."
    
    $fileContent = Get-Content $file -Raw
    $lines = $fileContent -split "`r?`n"
    $updated = $false
    
    # Process in reverse order to maintain indices
    $itemsToUpdate = $group.Group | Sort-Object LineNumber -Descending
    
    foreach ($item in $itemsToUpdate) {
        $needsUpdate = $false
        $newHelpText = $item.HelpText
        
        # Generate synopsis if missing
        if (-not $item.HasSynopsis) {
            if ($item.FunctionName) {
                $synopsis = Generate-Synopsis $item.FunctionName
            }
            else {
                $synopsis = "Alias for ``$($item.TargetCommand)``"
            }
            $newHelpText = ".SYNOPSIS`n    $synopsis`n`n" + $newHelpText
            $needsUpdate = $true
        }
        
        # Generate description if missing
        if (-not $item.HasDescription) {
            if ($item.FunctionName) {
                $description = Generate-Description $item.FunctionName $item.HelpText
            }
            else {
                $description = "Provides a shorthand for the ``$($item.TargetCommand)`` command."
            }
            $newHelpText = $newHelpText + "`n`n.DESCRIPTION`n    $description"
            $needsUpdate = $true
        }
        
        if ($needsUpdate) {
            # Find the comment block in the file
            $beforeText = $fileContent.Substring(0, $item.CommentStart)
            $afterText = $fileContent.Substring($item.CommentEnd)
            $commentMatches = [regex]::Matches($beforeText, '<#[\s\S]*?#>')
            
            if ($commentMatches.Count -gt 0) {
                $oldComment = $commentMatches[-1].Value
                $newComment = "<#`n$newHelpText`n#>"
                $fileContent = $fileContent.Replace($oldComment, $newComment)
                $updated = $true
                $name = if ($item.FunctionName) { $item.FunctionName } else { $item.AliasName }
                Write-Output "  Updated help for $name"
            }
        }
    }
    
    if ($updated) {
        Set-Content -Path $file -Value $fileContent -NoNewline
        Write-Output "  Saved updates to $file"
    }
}

function Generate-Synopsis {
    param([string]$FunctionName)
    
    # Generate synopsis based on function name patterns
    if ($FunctionName -match '^Set-Location(.+)$') {
        $target = $matches[1]
        return "Changes to the $target directory."
    }
    elseif ($FunctionName -match '^Get-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Gets $what."
    }
    elseif ($FunctionName -match '^Set-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Sets $what."
    }
    elseif ($FunctionName -match '^Test-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Tests $what."
    }
    elseif ($FunctionName -match '^Show-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Shows $what."
    }
    elseif ($FunctionName -match '^Enable-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Enables $what."
    }
    elseif ($FunctionName -match '^Disable-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Disables $what."
    }
    elseif ($FunctionName -match '^Add-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Adds $what."
    }
    elseif ($FunctionName -match '^Remove-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Removes $what."
    }
    elseif ($FunctionName -match '^Update-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Updates $what."
    }
    else {
        $readable = $FunctionName -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Performs $readable operation."
    }
}

function Generate-Description {
    param([string]$FunctionName, [string]$ExistingHelp)
    
    # Try to extract description from existing help if available
    if ($ExistingHelp -match '(?s)\.NOTES\s*\n\s*(.+?)(?=\n\s*\.|$)') {
        $notes = $matches[1].Trim()
        if ($notes.Length -lt 200) {
            return $notes
        }
    }
    
    # Generate description based on function name
    if ($FunctionName -match '^Set-Location(.+)$') {
        $target = $matches[1]
        return "Navigates to the user's $target folder."
    }
    elseif ($FunctionName -match '^Get-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Retrieves information about $what."
    }
    elseif ($FunctionName -match '^Set-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Configures or sets $what."
    }
    elseif ($FunctionName -match '^Test-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Checks if $what meets specified conditions."
    }
    elseif ($FunctionName -match '^Show-(.+)$') {
        $what = $matches[1] -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Displays information about $what."
    }
    else {
        $readable = $FunctionName -replace '([A-Z])', ' $1' -replace '^ ', ''
        return "Provides functionality for $readable."
    }
}

Write-Output "`nDone processing files."


