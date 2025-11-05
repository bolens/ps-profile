<#
scripts/utils/generate-docs.ps1

Generates API documentation from comment-based help in PowerShell functions.

Usage: pwsh -NoProfile -File scripts/utils/generate-docs.ps1
#>

param(
    [string]$OutputPath = "docs"
)

# Helper function for GetRelativePath compatibility with older .NET versions
function Get-RelativePath {
    param([string]$From, [string]$To)

    $fromUri = [Uri]::new($From)
    $toUri = [Uri]::new($To)

    if ($fromUri.Scheme -ne $toUri.Scheme) {
        return $To
    }

    $relativeUri = $fromUri.MakeRelativeUri($toUri)
    $relativePath = [Uri]::UnescapeDataString($relativeUri.ToString())

    # Convert forward slashes to backslashes on Windows
    if ([Environment]::OSVersion.Platform -eq 'Win32NT') {
        $relativePath = $relativePath -replace '/', '\'
    }

    return $relativePath
}

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)

# Compile regex patterns once for better performance
$regexCommentBlock = [regex]::new('<#[\s\S]*?#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexParameter = [regex]::new('(?s)\.PARAMETER\s+(\w+)\s*\n\s*(.+?)(?=\n\s*\.(?:PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexExample = [regex]::new('(?s)\.EXAMPLE\s*\n\s*(.+?)(?=\n\s*\.(?:EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexLink = [regex]::new('(?s)\.LINK\s*\n\s*(.+?)(?=\n\s*\.(?:LINK)|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexEmptyLine = [regex]::new('^\s*$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexCodeLine = [regex]::new('^\s*[A-Za-z]', [System.Text.RegularExpressions.RegexOptions]::Compiled)

# Handle OutputPath - if it's absolute, use it directly, otherwise join with repo root
if ([System.IO.Path]::IsPathRooted($OutputPath)) {
    $docsPath = $OutputPath
}
else {
    $docsPath = Join-Path $repoRoot $OutputPath
}

$profilePath = Join-Path $repoRoot 'profile.d'

Write-Output "Generating API documentation..."

# Create docs directory if it doesn't exist
if (-not (Test-Path $docsPath)) {
    New-Item -ItemType Directory -Path $docsPath -Force | Out-Null
}

# Track which commands we're documenting (to clean up stale docs later)
# Use List for better performance than array concatenation
$documentedCommandNames = [System.Collections.Generic.List[string]]::new()

# Find all functions with comment-based help
# Use List for better performance than array concatenation
$functions = [System.Collections.Generic.List[PSCustomObject]]::new()
$aliases = [System.Collections.Generic.List[PSCustomObject]]::new()

Get-ChildItem -Path $profilePath -Filter '*.ps1' | ForEach-Object {
    $file = $_.FullName
    Write-Output "Scanning $file for functions..."

    # Parse the file content to find functions using AST
    $content = Get-Content $file -Raw
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
    $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)

    foreach ($funcAst in $functionAsts) {
        $functionName = $funcAst.Name

        # Skip functions with colons (like global:..) as they are internal aliases
        if ($functionName -match ':') {
            continue
        }

        $start = $funcAst.Extent.StartOffset

        # Build function signature
        $signature = $functionName
        if ($funcAst.Parameters) {
            $paramList = $funcAst.Parameters | ForEach-Object {
                $paramName = $_.Name.VariablePath.UserPath
                $paramType = if ($_.StaticType) { "[$($_.StaticType.Name)]" } else { "" }
                "$paramType`$$paramName"
            }
            if ($paramList) {
                $signature += " " + ($paramList -join ", ")
            }
        }

        # Get text before the function
        $beforeText = $content.Substring(0, $start)

        # Find the last comment block before the function
        $commentMatches = $regexCommentBlock.Matches($beforeText)
        if ($commentMatches.Count -gt 0) {
            $helpContent = $commentMatches[-1].Value  # Last comment block
            # Remove the comment markers
            $helpContent = $helpContent -replace '^<#\s*', '' -replace '\s*#>$', ''
        }
        else {
            continue  # No comment block, skip
        }

        # Trim leading/trailing whitespace from help content
        $helpContent = $helpContent.Trim()

        # Remove carriage returns
        $helpContent = $helpContent -replace '\r', ''

        # Normalize indentation by removing common leading spaces
        $lines = $helpContent -split "\r?\n"
        $minIndent = ($lines | Where-Object { $_ -match '\S' } | ForEach-Object { ($_.Length - $_.TrimStart().Length) } | Measure-Object -Minimum).Minimum
        if ($minIndent -gt 0) {
            $lines = $lines | ForEach-Object { if ($_.Length -ge $minIndent) { $_.Substring($minIndent) } else { $_ } }
        }
        $helpContent = $lines -join "`n"

        # Parse the help content - extract all sections
        $synopsis = ""
        $description = ""
        # Use List for better performance than array concatenation
        $parameters = [System.Collections.Generic.List[PSCustomObject]]::new()
        $examples = [System.Collections.Generic.List[string]]::new()
        $outputs = ""
        $notes = ""
        $inputs = ""
        $links = [System.Collections.Generic.List[string]]::new()

        # Extract SYNOPSIS (improved regex to work even without DESCRIPTION)
        if ($helpContent -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.(?:DESCRIPTION|PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)') {
            $synopsis = $matches[1].Trim()
        }

        # Extract DESCRIPTION (improved to capture multi-line)
        if ($helpContent -match '(?s)\.DESCRIPTION\s*\n\s*(.+?)(?=\n\s*\.(?:PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)') {
            $description = $matches[1].Trim()
            # Clean up multi-line descriptions
            $description = $description -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
        }

        # Extract PARAMETERS with improved regex for multi-line descriptions
        $paramMatches = $regexParameter.Matches($helpContent)
        foreach ($paramMatch in $paramMatches) {
            $paramName = $paramMatch.Groups[1].Value
            $paramDesc = $paramMatch.Groups[2].Value.Trim()
            # Clean up multi-line parameter descriptions
            $paramDesc = $paramDesc -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
            
            # Find matching parameter details from AST (if available)
            $paramDetail = $null
            if ($funcAst.Parameters) {
                foreach ($paramAst in $funcAst.Parameters) {
                    if ($paramAst.Name.VariablePath.UserPath -eq $paramName) {
                        $paramType = if ($paramAst.StaticType) { "[$($paramAst.StaticType.Name)]" } else { "" }
                        $isMandatory = $false
                        $isPipeline = $false
                        $position = $null
                        
                        if ($paramAst.Attributes) {
                            foreach ($attr in $paramAst.Attributes) {
                                try {
                                    $attrTypeName = $attr.TypeName.GetReflectionType().Name
                                    if ($attrTypeName -eq 'ParameterAttribute') {
                                        foreach ($namedArg in $attr.NamedArguments) {
                                            if ($namedArg.ArgumentName -eq 'Mandatory' -and $namedArg.Argument.Value) {
                                                $isMandatory = $true
                                            }
                                            if ($namedArg.ArgumentName -eq 'ValueFromPipeline' -and $namedArg.Argument.Value) {
                                                $isPipeline = $true
                                            }
                                            if ($namedArg.ArgumentName -eq 'Position' -and $namedArg.Argument.Value) {
                                                $position = $namedArg.Argument.Value
                                            }
                                        }
                                    }
                                }
                                catch {
                                    # Skip attributes we can't parse
                                }
                            }
                        }
                        
                        $paramDetail = [PSCustomObject]@{
                            Type      = $paramType
                            Mandatory = $isMandatory
                            Pipeline  = $isPipeline
                            Position  = $position
                        }
                        break
                    }
                }
            }
            
            $parameters.Add([PSCustomObject]@{
                    Name        = $paramName
                    Description = $paramDesc
                    Type        = if ($paramDetail) { $paramDetail.Type } else { "" }
                    Mandatory   = if ($paramDetail) { $paramDetail.Mandatory } else { $false }
                    Pipeline    = if ($paramDetail) { $paramDetail.Pipeline } else { $false }
                    Position    = if ($paramDetail) { $paramDetail.Position } else { $null }
                })
        }

        # Extract EXAMPLES (improved to capture multi-line examples)
        $exampleMatches = $regexExample.Matches($helpContent)
        foreach ($exampleMatch in $exampleMatches) {
            $examples.Add($exampleMatch.Groups[1].Value.Trim())
        }

        # Extract OUTPUTS
        if ($helpContent -match '(?s)\.OUTPUTS\s*\n\s*(.+?)(?=\n\s*\.(?:NOTES|INPUTS|LINK)|$)') {
            $outputs = $matches[1].Trim()
            $outputs = $outputs -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
        }

        # Extract NOTES
        if ($helpContent -match '(?s)\.NOTES\s*\n\s*(.+?)(?=\n\s*\.(?:INPUTS|LINK)|$)') {
            $notes = $matches[1].Trim()
            $notes = $notes -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
        }

        # Extract INPUTS
        if ($helpContent -match '(?s)\.INPUTS\s*\n\s*(.+?)(?=\n\s*\.(?:LINK)|$)') {
            $inputs = $matches[1].Trim()
            $inputs = $inputs -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
        }

        # Extract LINKS
        $linkMatches = $regexLink.Matches($helpContent)
        foreach ($linkMatch in $linkMatches) {
            $links.Add($linkMatch.Groups[1].Value.Trim())
        }

        $functions.Add([PSCustomObject]@{
                Name        = $functionName
                Signature   = $signature
                Synopsis    = $synopsis
                Description = $description
                Parameters  = $parameters
                Examples    = $examples
                Outputs     = $outputs
                Notes       = $notes
                Inputs      = $inputs
                Links       = $links
                File        = $file
            })
    }
    
    # Detect aliases (Set-Alias and Set-AgentModeAlias)
    $allLines = Get-Content $file -Raw -ErrorAction SilentlyContinue
    if ($allLines) {
        $lines = $allLines -split "`r?`n"
        for ($i = 0; $i -lt $lines.Count; $i++) {
            $line = $lines[$i].Trim()
            $aliasName = $null
            $targetCommand = $null
            
            # Match Set-Alias patterns: Set-Alias -Name <alias> -Value <target>
            if ($line -match 'Set-Alias\s+-Name\s+([A-Za-z0-9_\-]+)\s+-Value\s+([A-Za-z0-9_\-\.\~]+)') {
                $aliasName = $matches[1]
                $targetCommand = $matches[2]
            }
            # Match Set-AgentModeAlias patterns
            elseif ($line -match 'Set-AgentModeAlias\s+-Name\s+[\x27\x22]([A-Za-z0-9_\-]+)[\x27\x22]\s+-Target\s+[\x27\x22]?([A-Za-z0-9_\-\.\~]+)') {
                $aliasName = $matches[1]
                $targetCommand = $matches[2]
            }
            # Also check for multi-line Set-Alias (Name and Value on separate lines)
            elseif ($line -match 'Set-Alias\s+-Name\s+([A-Za-z0-9_\-]+)') {
                $aliasName = $matches[1]
                # Check next few lines for -Value
                for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $lines.Count); $j++) {
                    $nextLine = $lines[$j].Trim()
                    if ($nextLine -match '-Value\s+([A-Za-z0-9_\-\.\~]+)') {
                        $targetCommand = $matches[1]
                        break
                    }
                    # Stop if we hit another command or empty line (use compiled regex for better performance)
                    if ($regexEmptyLine.IsMatch($nextLine) -or $regexCodeLine.IsMatch($nextLine)) {
                        break
                    }
                }
            }
            
            if ($aliasName -and $targetCommand) {
                # Look for comment block before the alias (up to 30 lines back)
                $helpContent = ""
                $beforeText = ""
                if ($i -gt 0) {
                    $startIdx = [Math]::Max(0, $i - 30)
                    $beforeText = ($lines[$startIdx..($i - 1)] -join "`n")
                }
                
                # Find the last comment block before the alias
                $commentMatches = $regexCommentBlock.Matches($beforeText)
                if ($commentMatches.Count -gt 0) {
                    $helpContent = $commentMatches[-1].Value
                    $helpContent = $helpContent -replace '^<#\s*', '' -replace '\s*#>$', ''
                    $helpContent = $helpContent.Trim()
                    
                    # Normalize indentation
                    $helpLines = $helpContent -split "\r?\n"
                    $minIndent = ($helpLines | Where-Object { $_ -match '\S' } | ForEach-Object { ($_.Length - $_.TrimStart().Length) } | Measure-Object -Minimum).Minimum
                    if ($minIndent -gt 0) {
                        $helpLines = $helpLines | ForEach-Object { if ($_.Length -ge $minIndent) { $_.Substring($minIndent) } else { $_ } }
                    }
                    $helpContent = $helpLines -join "`n"
                }
                
                # Extract synopsis and description from comment block
                $synopsis = ""
                $description = ""
                
                if ($helpContent) {
                    if ($helpContent -match '(?s)\.SYNOPSIS\s*\n\s*(.+?)(?=\n\s*\.(?:DESCRIPTION|PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)') {
                        $synopsis = $matches[1].Trim()
                        $synopsis = $synopsis -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
                    }
                    
                    if ($helpContent -match '(?s)\.DESCRIPTION\s*\n\s*(.+?)(?=\n\s*\.(?:PARAMETER|EXAMPLE|OUTPUTS|NOTES|INPUTS|LINK)|$)') {
                        $description = $matches[1].Trim()
                        $description = $description -replace '\r\n', ' ' -replace '\n', ' ' -replace '\s+', ' '
                    }
                    
                    # If no structured help, try to get first meaningful line
                    if (-not $synopsis -and -not $description) {
                        foreach ($helpLine in $helpLines) {
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
                
                # If no synopsis found, try to get description from the target function
                if (-not $synopsis) {
                    $targetFunc = $functions | Where-Object { $_.Name -eq $targetCommand } | Select-Object -First 1
                    if ($targetFunc -and $targetFunc.Synopsis) {
                        $synopsis = $targetFunc.Synopsis
                    }
                }
                
                $aliases.Add([PSCustomObject]@{
                        Name        = $aliasName
                        Target      = $targetCommand
                        Synopsis    = $synopsis
                        Description = $description
                        File        = $file
                    })
            }
        }
    }
}

if ($functions.Count -eq 0 -and $aliases.Count -eq 0) {
    Write-Output "No functions or aliases with documentation found."
    exit 0
}

Write-Output "Found $($functions.Count) functions and $($aliases.Count) aliases with documentation."

# Generate markdown documentation
foreach ($function in $functions) {
    $mdFile = Join-Path $docsPath "$($function.Name).md"
    $documentedCommandNames.Add($function.Name)

    $content = "# $($function.Name)`n`n"
    $content += "## Synopsis`n`n"
    $content += "$($function.Synopsis)`n`n"
    $content += "## Description`n`n"
    $content += "$($function.Description)`n`n"
    $content += "## Signature`n`n"
    $codeFence = '```'
    $content += "$codeFence" + "powershell`n"
    $content += "$($function.Signature)`n"
    $content += "$codeFence"

    if ($function.Parameters.Count -gt 0) {
        $content += "`n`n## Parameters`n"
        foreach ($param in $function.Parameters) {
            $content += "`n### -$($param.Name)`n`n"
            
            # Add parameter type if available
            if ($param.Type) {
                $content += "**Type:** $($param.Type)`n`n"
            }
            
            # Add attributes
            # Use List for better performance than array concatenation
            $attrs = [System.Collections.Generic.List[string]]::new()
            if ($param.Mandatory) { $attrs.Add("Mandatory") }
            if ($param.Pipeline) { $attrs.Add("Accepts pipeline input") }
            if ($param.Position -ne $null) { $attrs.Add("Position: $($param.Position)") }
            if ($attrs.Count -gt 0) {
                $content += "**Attributes:** " + ($attrs -join ", ") + "`n`n"
            }
            
            # Add description
            $content += "$($param.Description)`n"
        }
    }
    else {
        $content += "`n`n## Parameters`n`nNo parameters."
    }
    
    # Add INPUTS section if available
    if ($function.Inputs) {
        $content += "`n`n## Inputs`n`n$($function.Inputs)`n"
    }
    
    # Add OUTPUTS section if available
    if ($function.Outputs) {
        $content += "`n`n## Outputs`n`n$($function.Outputs)`n"
    }

    $content += "`n`n## Examples"

    if ($function.Examples.Count -gt 0) {
        for ($i = 0; $i -lt $function.Examples.Count; $i++) {
            $content += "`n`n### Example $($i + 1)`n`n```powershell`n$($function.Examples[$i])`n````"
        }
    }
    else {
        $content += "`n`nNo examples provided."
    }
    
    # Add NOTES section if available
    if ($function.Notes) {
        $content += "`n`n## Notes`n`n$($function.Notes)`n"
    }
    
    # Add LINKS section if available
    if ($function.Links.Count -gt 0) {
        $content += "`n`n## Related Links`n"
        foreach ($link in $function.Links) {
            $content += "`n- $link`n"
        }
    }
    
    # Add ALIASES section if this function has any aliases
    $functionAliases = $aliases | Where-Object { $_.Target -eq $function.Name }
    # Deduplicate by alias name, keeping only one entry per alias name
    # Use a hashtable to track unique aliases, preferring ones with synopsis
    $aliasHash = @{}
    foreach ($alias in $functionAliases) {
        if (-not $aliasHash.ContainsKey($alias.Name)) {
            $aliasHash[$alias.Name] = $alias
        }
        else {
            # Prefer the one with synopsis, or replace if current has synopsis and stored doesn't
            $stored = $aliasHash[$alias.Name]
            if ($alias.Synopsis -and -not $stored.Synopsis) {
                $aliasHash[$alias.Name] = $alias
            }
            elseif ($alias.Synopsis -and $stored.Synopsis) {
                # Both have synopsis, prefer the last one (more specific definition)
                $aliasHash[$alias.Name] = $alias
            }
        }
    }
    $uniqueAliases = $aliasHash.Values | Sort-Object Name
    if ($uniqueAliases.Count -gt 0) {
        $content += "`n`n## Aliases`n`n"
        $content += "This function has the following aliases:`n`n"
        foreach ($alias in $uniqueAliases) {
            $content += "- ``$($alias.Name)`` - "
            if ($alias.Synopsis) {
                $content += $alias.Synopsis
            }
            else {
                $content += "Alias for ``$($function.Name)``"
            }
            $content += "`n"
        }
    }

    $content += "`n`n## Source`n`nDefined in: $(Get-RelativePath $docsPath $function.File)"

    $content | Out-File -FilePath $mdFile -Encoding UTF8 -NoNewline:$false
    Write-Output "Generated documentation: $mdFile"
}

# Generate markdown documentation for aliases
foreach ($alias in $aliases) {
    $mdFile = Join-Path $docsPath "$($alias.Name).md"
    $documentedCommandNames += $alias.Name
    
    $content = "# $($alias.Name)`n`n"
    $content += "## Synopsis`n`n"
    $content += "$($alias.Synopsis)`n`n"
    $content += "## Description`n`n"
    $content += "$($alias.Description)`n`n"
    $content += "## Alias Information`n`n"
    $content += "**Alias for:** ``$($alias.Target)```n`n"
    $content += "This is an alias that points to the ``$($alias.Target)`` command. Use this alias as a shorthand for the full command name.`n`n"
    $content += "## Examples`n`n"
    $content += "No examples provided.`n`n"
    $content += "## Source`n`n"
    $content += "Defined in: $(Get-RelativePath $docsPath $alias.File)"
    
    $content | Out-File -FilePath $mdFile -Encoding UTF8 -NoNewline:$false
    Write-Output "Generated alias documentation: $mdFile"
}

# Generate index file
$groupedFunctions = $functions | Group-Object { [System.IO.Path]::GetFileName($_.File) } | Sort-Object Name

$indexContent = "# PowerShell Profile API Documentation`n`n"
$indexContent += "This documentation is automatically generated from comment-based help in the profile functions and aliases.`n`n"
$indexContent += "**Total Functions:** $($functions.Count)`n"
$indexContent += "**Total Aliases:** $($aliases.Count)`n"
$indexContent += "**Generated:** $(Get-Date -Format "yyyy-MM-dd HH:mm:ss")`n`n"
$indexContent += "## Functions by Fragment`n`n"

foreach ($group in $groupedFunctions) {
    $fragmentName = $group.Name -replace '\.ps1$', ''
    $functionList = $group.Group | Sort-Object Name | ForEach-Object { "- [$($_.Name)]($($_.Name).md) - $($_.Synopsis)" }
    $indexContent += "`n### $fragmentName ($($group.Count) functions)`n`n$($functionList -join "`n")`n"
}

# Add aliases section
if ($aliases.Count -gt 0) {
    $groupedAliases = $aliases | Group-Object { [System.IO.Path]::GetFileName($_.File) } | Sort-Object Name
    $indexContent += "`n`n## Aliases by Fragment`n`n"
    
    foreach ($group in $groupedAliases) {
        $fragmentName = $group.Name -replace '\.ps1$', ''
        $aliasList = $group.Group | Sort-Object Name | ForEach-Object { 
            $desc = if ($_.Synopsis) { $_.Synopsis } else { "Alias for ``$($_.Target)``" }
            "- [$($_.Name)]($($_.Name).md) - $desc (alias for ``$($_.Target)``)"
        }
        $indexContent += "`n### $fragmentName ($($group.Count) aliases)`n`n$($aliasList -join "`n")`n"
    }
}

$indexContent += "`n`n## Generation`n`n"
$indexContent += "This documentation was generated from the comment-based help in the profile fragments."

$indexContent | Out-File -FilePath (Join-Path $docsPath 'README.md') -Encoding UTF8 -NoNewline:$false

# Clean up stale documentation files
Write-Output "`nCleaning up stale documentation..."
$allDocFiles = Get-ChildItem -Path $docsPath -Filter '*.md' -Exclude 'README.md' -ErrorAction SilentlyContinue
$staleDocs = $allDocFiles | Where-Object { $_.BaseName -notin $documentedCommandNames }

if ($staleDocs.Count -gt 0) {
    Write-Output "Removing $($staleDocs.Count) stale documentation file(s):"
    foreach ($staleDoc in $staleDocs) {
        Write-Output "  - Removing $($staleDoc.Name)"
        Remove-Item -Path $staleDoc.FullName -Force
    }
}
else {
    Write-Output "No stale documentation files found."
}

Write-Output "`nAPI documentation generated in: $docsPath"
Write-Output "Generated documentation for $($functions.Count) functions and $($aliases.Count) aliases."
