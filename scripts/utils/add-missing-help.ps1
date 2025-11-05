<#
scripts/utils/add-missing-help.ps1

Adds missing .SYNOPSIS and .DESCRIPTION sections to comment-based help blocks.
#>

$repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$profilePath = Join-Path $repoRoot 'profile.d'

Write-Output "Scanning for functions and aliases missing Synopsis/Description..."

# Compile regex patterns once for better performance
$commentBlockRegex = [regex]'<#[\s\S]*?#>'
$synopsisRegex = [regex]'(?s)\.SYNOPSIS'
$descriptionRegex = [regex]'(?s)\.DESCRIPTION'
$setAliasRegex = [regex]'Set-Alias\s+-Name\s+([A-Za-z0-9_\-]+)\s+-Value\s+([A-Za-z0-9_\-\.\~]+)'
$setAgentModeAliasRegex = [regex]'Set-AgentModeAlias\s+-Name\s+[\x27\x22]([A-Za-z0-9_\-]+)[\x27\x22]\s+-Target\s+[\x27\x22]?([A-Za-z0-9_\-\.\~]+)'
$setAliasNameRegex = [regex]'Set-Alias\s+-Name\s+([A-Za-z0-9_\-]+)'
$valueRegex = [regex]'-Value\s+([A-Za-z0-9_\-\.\~]+)'
$emptyLineRegex = [regex]'^\s*$'
$codeLineRegex = [regex]'^\s*[A-Za-z]'

# Use List for better performance than array concatenation
$filesToUpdate = [System.Collections.Generic.List[PSCustomObject]]::new()
$fileContents = @{} # Cache file contents to avoid re-reading

Get-ChildItem -Path $profilePath -Filter '*.ps1' | ForEach-Object {
    $file = $_.FullName
    $content = Get-Content $file -Raw
    $fileContents[$file] = $content # Cache for later use
    $lines = $content -split "`r?`n"
    
    # Parse the file content to find functions using AST
    $ast = [System.Management.Automation.Language.Parser]::ParseFile($file, [ref]$null, [ref]$null)
    $functionAsts = $ast.FindAll({ $args[0] -is [System.Management.Automation.Language.FunctionDefinitionAst] }, $true)
    
    foreach ($funcAst in $functionAsts) {
        $functionName = $funcAst.Name
        
        # Skip functions with colons (like global:..) as they are internal aliases
        if ($regexColon.IsMatch($functionName)) {
            continue
        }
        
        $start = $funcAst.Extent.StartOffset
        $beforeText = $content.Substring(0, $start)
        
        # Find the last comment block before the function
        $commentMatches = $commentBlockRegex.Matches($beforeText)
        if ($commentMatches.Count -gt 0) {
            $helpContent = $commentMatches[-1].Value
            $helpText = $helpContent -replace '^<#\s*', '' -replace '\s*#>$', ''
            $helpText = $helpText.Trim()
            
            # Check if SYNOPSIS or DESCRIPTION are missing (combine checks)
            $hasSynopsis = $synopsisRegex.IsMatch($helpText)
            $hasDescription = $descriptionRegex.IsMatch($helpText)
            
            if (-not $hasSynopsis -or -not $hasDescription) {
                $commentStart = $commentMatches[-1].Index
                $commentEnd = $commentStart + $commentMatches[-1].Length
                
                # Efficient line number calculation using pre-calculated line offsets
                $lineNumber = ($content.Substring(0, $start) -split "`r?`n").Count
                
                $filesToUpdate.Add([PSCustomObject]@{
                        File           = $file
                        FunctionName   = $functionName
                        CommentStart   = $commentStart
                        CommentEnd     = $commentEnd
                        HelpText       = $helpText
                        HasSynopsis    = $hasSynopsis
                        HasDescription = $hasDescription
                        LineNumber     = $lineNumber
                    })
            }
        }
    }
    
    # Also check for aliases with comment blocks
    for ($i = 0; $i -lt $lines.Count; $i++) {
        $line = $lines[$i].Trim()
        $aliasName = $null
        $targetCommand = $null
        
        # Match Set-Alias patterns using compiled regex
        $match = $setAliasRegex.Match($line)
        if ($match.Success) {
            $aliasName = $match.Groups[1].Value
            $targetCommand = $match.Groups[2].Value
        }
        else {
            $match = $setAgentModeAliasRegex.Match($line)
            if ($match.Success) {
                $aliasName = $match.Groups[1].Value
                $targetCommand = $match.Groups[2].Value
            }
            else {
                $match = $setAliasNameRegex.Match($line)
                if ($match.Success) {
                    $aliasName = $match.Groups[1].Value
                    for ($j = $i + 1; $j -lt [Math]::Min($i + 5, $lines.Count); $j++) {
                        $nextLine = $lines[$j].Trim()
                        $valueMatch = $valueRegex.Match($nextLine)
                        if ($valueMatch.Success) {
                            $targetCommand = $valueMatch.Groups[1].Value
                            break
                        }
                        # Use compiled regex for better performance
                        if ($emptyLineRegex.IsMatch($nextLine) -or $codeLineRegex.IsMatch($nextLine)) {
                            break
                        }
                    }
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
            
            $commentMatches = $commentBlockRegex.Matches($beforeText)
            if ($commentMatches.Count -gt 0) {
                $helpContent = $commentMatches[-1].Value
                $helpText = $helpContent -replace '^<#\s*', '' -replace '\s*#>$', ''
                $helpText = $helpText.Trim()
                
                $hasSynopsis = $synopsisRegex.IsMatch($helpText)
                $hasDescription = $descriptionRegex.IsMatch($helpText)
                
                if (-not $hasSynopsis -or -not $hasDescription) {
                    $filesToUpdate.Add([PSCustomObject]@{
                            File           = $file
                            AliasName      = $aliasName
                            TargetCommand  = $targetCommand
                            HelpText       = $helpText
                            HasSynopsis    = $hasSynopsis
                            HasDescription = $hasDescription
                            LineNumber     = $i + 1
                        })
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
    
    # Use cached content instead of re-reading file
    $fileContent = $fileContents[$file]
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
            # Find the comment block in the file using cached regex
            $beforeText = $fileContent.Substring(0, $item.CommentStart)
            $commentMatches = $commentBlockRegex.Matches($beforeText)
            
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

# Compile regex patterns once for function name parsing (used in helper functions)
$regexSetLocation = [regex]::new('^Set-Location(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexGet = [regex]::new('^Get-(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexSet = [regex]::new('^Set-(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexTest = [regex]::new('^Test-(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexShow = [regex]::new('^Show-(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexEnable = [regex]::new('^Enable-(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexDisable = [regex]::new('^Disable-(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexAdd = [regex]::new('^Add-(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexRemove = [regex]::new('^Remove-(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexUpdate = [regex]::new('^Update-(.+)$', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexCamelCase = [regex]::new('([A-Z])', [System.Text.RegularExpressions.RegexOptions]::Compiled)
$regexNotes = [regex]::new('(?s)\.NOTES\s*\n\s*(.+?)(?=\n\s*\.|$)', [System.Text.RegularExpressions.RegexOptions]::Compiled)

function Generate-Synopsis {
    param([string]$FunctionName)
    
    # Generate synopsis based on function name patterns
    $match = $regexSetLocation.Match($FunctionName)
    if ($match.Success) {
        $target = $match.Groups[1].Value
        return "Changes to the $target directory."
    }
    $match = $regexGet.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Gets $what."
    }
    $match = $regexSet.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Sets $what."
    }
    $match = $regexTest.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Tests $what."
    }
    $match = $regexShow.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Shows $what."
    }
    $match = $regexEnable.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Enables $what."
    }
    $match = $regexDisable.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Disables $what."
    }
    $match = $regexAdd.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Adds $what."
    }
    $match = $regexRemove.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Removes $what."
    }
    $match = $regexUpdate.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Updates $what."
    }
    $readable = $regexCamelCase.Replace($FunctionName, ' $1') -replace '^ ', ''
    return "Performs $readable operation."
}

function Generate-Description {
    param([string]$FunctionName, [string]$ExistingHelp)
    
    # Try to extract description from existing help if available
    $notesMatch = $regexNotes.Match($ExistingHelp)
    if ($notesMatch.Success) {
        $notes = $notesMatch.Groups[1].Value.Trim()
        if ($notes.Length -lt 200) {
            return $notes
        }
    }
    
    # Generate description based on function name
    $match = $regexSetLocation.Match($FunctionName)
    if ($match.Success) {
        $target = $match.Groups[1].Value
        return "Navigates to the user's $target folder."
    }
    $match = $regexGet.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Retrieves information about $what."
    }
    $match = $regexSet.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Configures or sets $what."
    }
    $match = $regexTest.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Checks if $what meets specified conditions."
    }
    $match = $regexShow.Match($FunctionName)
    if ($match.Success) {
        $what = $regexCamelCase.Replace($match.Groups[1].Value, ' $1') -replace '^ ', ''
        return "Displays information about $what."
    }
    $readable = $regexCamelCase.Replace($FunctionName, ' $1') -replace '^ ', ''
    return "Provides functionality for $readable."
}

Write-Output "`nDone processing files."


