<#
scripts/utils/code-quality/add-comment-help.ps1

.SYNOPSIS
    Adds comment-based help to all functions that are missing it.

.DESCRIPTION
    Scans all PowerShell files in the project (profile.d, scripts, tests) and adds
    comment-based help blocks to functions that don't have them. The help blocks
    are generated based on function signatures and inserted before function definitions.

.PARAMETER Path
    If specified, only processes files in this path. Otherwise, processes all PowerShell files.

.PARAMETER DryRun
    If specified, shows what would be added without actually modifying files.

.PARAMETER Force
    If specified, overwrites existing comment blocks that don't contain .SYNOPSIS or .DESCRIPTION.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\code-quality\add-comment-help.ps1

    Adds comment-based help to all functions missing it.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\code-quality\add-comment-help.ps1 -Path profile.d -DryRun

    Shows what would be added to functions in profile.d without modifying files.
#>

param(
    [string]$Path = $null,

    [switch]$DryRun,

    [switch]$Force
)

# Import PathResolution first (required for ModuleImport to work)
$scriptsDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'path' 'PathResolution.psm1'
if ($pathResolutionPath -and -not [string]::IsNullOrWhiteSpace($pathResolutionPath) -and -not (Test-Path -LiteralPath $pathResolutionPath)) {
    throw "PathResolution module not found at: $pathResolutionPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop

# Import ModuleImport (bootstrap)
$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
if ($moduleImportPath -and -not [string]::IsNullOrWhiteSpace($moduleImportPath) -and -not (Test-Path -LiteralPath $moduleImportPath)) {
    throw "ModuleImport module not found at: $moduleImportPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'AstParsing' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'CommentHelp' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileContent' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Determine paths to scan
$pathsToScan = @()
if (-not [string]::IsNullOrWhiteSpace($Path)) {
    $resolvedPath = if ([System.IO.Path]::IsPathRooted($Path)) {
        $Path
    }
    else {
        Join-Path $repoRoot $Path
    }
    if (Test-Path -LiteralPath $resolvedPath) {
        $pathsToScan = @($resolvedPath)
    }
    else {
        Write-ScriptMessage -Message "Path not found: $resolvedPath" -IsError
        Exit-WithCode -ExitCode [ExitCode]::ValidationFailure -Message "Path not found: $resolvedPath"
    }
}
else {
    # Default: scan profile.d, scripts, and tests
    $pathsToScan = @(
        (Join-Path $repoRoot 'profile.d'),
        (Join-Path $repoRoot 'scripts'),
        (Join-Path $repoRoot 'tests')
    )
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[code-quality.add-comment-help] Starting comment help addition"
    Write-Verbose "[code-quality.add-comment-help] Paths to scan: $($pathsToScan -join ', ')"
    Write-Verbose "[code-quality.add-comment-help] Dry run: $DryRun, Force: $Force"
}

<#
.SYNOPSIS
    Generates a comment-based help block for a function.

.DESCRIPTION
    Creates a comment-based help block based on the function's name, parameters, and signature.

.PARAMETER FuncAst
    The FunctionDefinitionAst node.

.PARAMETER Content
    The full file content as a string.

.OUTPUTS
    System.String. The generated comment-based help block.
#>
function New-CommentHelpBlock {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FuncAst,

        [Parameter(Mandatory)]
        [string]$Content
    )

    $functionName = $FuncAst.Name

    # Skip functions with colons (like global:..) as they are internal
    if ($functionName -match ':') {
        return $null
    }

    # Extract function name without scope
    $displayName = $functionName -replace '^.*:', ''

    # Generate synopsis from function name by splitting on capital letters
    $words = $displayName -replace '([A-Z])', ' $1' -split ' ' | Where-Object { $_ -ne '' }
    
    # Map common verbs to their descriptions
    $verbMap = @{
        'Get'        = 'Gets'
        'Set'        = 'Sets'
        'New'        = 'Creates'
        'Remove'     = 'Removes'
        'Invoke'     = 'Invokes'
        'Test'       = 'Tests'
        'Start'      = 'Starts'
        'Stop'       = 'Stops'
        'Add'        = 'Adds'
        'Update'     = 'Updates'
        'Find'       = 'Finds'
        'Convert'    = 'Converts'
        'Connect'    = 'Connects'
        'Disconnect' = 'Disconnects'
        'Export'     = 'Exports'
        'Import'     = 'Imports'
        'Backup'     = 'Backups'
        'Restore'    = 'Restores'
        'Query'      = 'Queries'
        'Switch'     = 'Switches'
        'Open'       = 'Opens'
        'Build'      = 'Builds'
        'Publish'    = 'Publishes'
        'Install'    = 'Installs'
        'Uninstall'  = 'Uninstalls'
        'Enable'     = 'Enables'
        'Disable'    = 'Disables'
        'Initialize' = 'Initializes'
        'Ensure'     = 'Ensures'
        'Reload'     = 'Reloads'
        'Edit'       = 'Edits'
        'Copy'       = 'Copies'
        'Move'       = 'Moves'
        'Resolve'    = 'Resolves'
        'Compare'    = 'Compares'
        'Measure'    = 'Measures'
        'Select'     = 'Selects'
        'Format'     = 'Formats'
        'Write'      = 'Writes'
        'Read'       = 'Reads'
        'Parse'      = 'Parses'
        'Generate'   = 'Generates'
        'Show'       = 'Shows'
        'Save'       = 'Saves'
        'Load'       = 'Loads'
        'Send'       = 'Sends'
        'Register'   = 'Registers'
        'Unregister' = 'Unregisters'
        'Filter'     = 'Filters'
        'Calculate'  = 'Calculates'
        'Analyze'    = 'Analyzes'
        'Validate'   = 'Validates'
        'Check'      = 'Checks'
        'Verify'     = 'Verifies'
        'Time'       = 'Times'
    }

    if ($words.Count -gt 0 -and $verbMap.ContainsKey($words[0])) {
        $verb = $verbMap[$words[0]]
        $noun = ($words[1..($words.Count - 1)] -join ' ')
        if ($noun) {
            $synopsis = "$verb $noun."
        }
        else {
            $synopsis = "$verb operations."
        }
    }
    else {
        # Fallback: create a generic description
        $synopsis = "Performs operations related to $displayName."
    }

    # Generate description (same as synopsis for now, can be enhanced)
    $description = $synopsis

    # Extract parameters
    $paramBlock = if ($FuncAst.Body -and $FuncAst.Body.ParamBlock) {
        $FuncAst.Body.ParamBlock
    }
    elseif ($FuncAst.Parameters) {
        $FuncAst.Parameters
    }
    else {
        $null
    }

    $parameters = @()
    if ($paramBlock -and $paramBlock.Parameters) {
        foreach ($param in $paramBlock.Parameters) {
            $paramName = $param.Name.VariablePath.UserPath
            $paramType = if ($param.StaticType) { $param.StaticType.Name } else { "object" }
            $isMandatory = $false

            if ($param.Attributes) {
                foreach ($attr in $param.Attributes) {
                    if ($attr.TypeName.Name -eq 'Parameter') {
                        foreach ($namedArg in $attr.NamedArguments) {
                            if ($namedArg.ArgumentName -eq 'Mandatory' -and $namedArg.Argument.Value -eq $true) {
                                $isMandatory = $true
                                break
                            }
                        }
                    }
                }
            }

            $paramDesc = "The $paramName parameter."
            if ($isMandatory) {
                $paramDesc = "$paramDesc (Required)"
            }

            $parameters += @{
                Name        = $paramName
                Type        = $paramType
                Description = $paramDesc
                Mandatory   = $isMandatory
            }
        }
    }

    # Extract output type if available
    $outputType = "object"
    if ($FuncAst.Body -and $FuncAst.Body.Attributes) {
        foreach ($attr in $FuncAst.Body.Attributes) {
            if ($attr.TypeName.Name -eq 'OutputType') {
                if ($attr.PositionalArguments -and $attr.PositionalArguments.Count -gt 0) {
                    $outputTypeArg = $attr.PositionalArguments[0]
                    if ($outputTypeArg.Value) {
                        $outputType = $outputTypeArg.Value.ToString()
                    }
                    elseif ($outputTypeArg.StaticType) {
                        $outputType = $outputTypeArg.StaticType.Name
                    }
                }
            }
        }
    }

    # Build help block
    $helpLines = @()
    $helpLines += "<#"
    $helpLines += ".SYNOPSIS"
    $helpLines += "    $synopsis"
    $helpLines += ""
    $helpLines += ".DESCRIPTION"
    $helpLines += "    $description"
    
    if ($parameters.Count -gt 0) {
        $helpLines += ""
        foreach ($param in $parameters) {
            $helpLines += ".PARAMETER $($param.Name)"
            $helpLines += "    $($param.Description)"
            if ($parameters.IndexOf($param) -lt $parameters.Count - 1) {
                $helpLines += ""
            }
        }
    }

    $helpLines += ""
    $helpLines += ".OUTPUTS"
    $helpLines += "    $outputType"
    $helpLines += "#>"

    return $helpLines -join "`n"
}

<#
.SYNOPSIS
    Adds comment-based help to a function in a file.

.DESCRIPTION
    Inserts a comment-based help block before a function definition if one is missing.

.PARAMETER FilePath
    Path to the PowerShell file.

.PARAMETER FuncAst
    The FunctionDefinitionAst node.

.PARAMETER Content
    The full file content as a string.

.PARAMETER DryRun
    If specified, doesn't modify the file.

.OUTPUTS
    System.Boolean. True if help was added or already exists.
#>
function Add-CommentHelpToFunction {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FilePath,

        [Parameter(Mandatory)]
        [System.Management.Automation.Language.FunctionDefinitionAst]$FuncAst,

        [Parameter(Mandatory)]
        [string]$Content,

        [switch]$DryRun,

        [switch]$Force
    )

    $functionName = $FuncAst.Name

    # Check if function already has help
    $hasHelp = Test-FunctionHasHelp -FuncAst $FuncAst -Content $Content -CheckBody

    if ($hasHelp -and -not $Force) {
        return $true
    }

    # Generate help block
    $helpBlock = New-CommentHelpBlock -FuncAst $FuncAst -Content $Content
    if (-not $helpBlock) {
        return $false
    }

    # Find insertion point
    $startOffset = $FuncAst.Extent.StartOffset
    $startLine = $FuncAst.Extent.StartLineNumber

    # Get text before function
    $beforeText = $Content.Substring(0, $startOffset)

    # Detect line ending
    $lineEnding = if ($Content -match "`r`n") { "`r`n" } elseif ($Content -match "`n") { "`n" } else { "`r`n" }

    # Split content into lines
    $lines = $Content -split "`r?`n"

    # Calculate indentation from the function line
    $functionLine = $lines[$startLine - 1]
    $indentMatch = $functionLine -match '^(\s*)'
    $indent = if ($indentMatch) { $matches[1] } else { '' }

    # Check if there's already a comment block before the function
    $commentBlockRegex = [regex]::new('<#[\s\S]*?#>', [System.Text.RegularExpressions.RegexOptions]::Compiled)
    $commentMatches = $commentBlockRegex.Matches($beforeText)
    
    $insertionOffset = $startOffset
    $replaceComment = $false

    if ($commentMatches.Count -gt 0 -and $Force) {
        # Check if the last comment is immediately before the function
        $lastComment = $commentMatches[$commentMatches.Count - 1]
        $commentEnd = $lastComment.Index + $lastComment.Length
        $textBetween = $beforeText.Substring($commentEnd)
        
        if ($textBetween -match '^\s*$') {
            # Replace the existing comment block
            $insertionOffset = $lastComment.Index
            $replaceComment = $true
        }
    }

    # Find the start of the function's line for insertion
    if (-not $replaceComment) {
        # Find line start
        $lineStartOffset = 0
        for ($i = 0; $i -lt $startLine - 1; $i++) {
            $lineStartOffset += $lines[$i].Length + $lineEnding.Length
        }
        $insertionOffset = $lineStartOffset
    }

    # Indent help block
    $helpLines = $helpBlock -split "`n"
    $indentedHelpLines = $helpLines | ForEach-Object {
        if ($_ -match '^\s*$') {
            # Empty line - just return indent
            $indent
        }
        else {
            $indent + $_
        }
    }
    $indentedHelpBlock = $indentedHelpLines -join $lineEnding

    # Insert or replace help block
    if ($replaceComment) {
        $lastComment = $commentMatches[$commentMatches.Count - 1]
        $newContent = $Content.Remove($lastComment.Index, $lastComment.Length).Insert($lastComment.Index, $indentedHelpBlock)
    }
    else {
        $insertText = $indentedHelpBlock + $lineEnding
        $newContent = $Content.Insert($insertionOffset, $insertText)
    }

    if (-not $DryRun) {
        try {
            # Preserve original encoding
            $encoding = [System.Text.Encoding]::UTF8
            if (Test-Path -LiteralPath $FilePath) {
                $bytes = [System.IO.File]::ReadAllBytes($FilePath)
                $preamble = [System.Text.Encoding]::UTF8.GetPreamble()
                if ($bytes.Length -ge $preamble.Length) {
                    $hasBom = $true
                    for ($i = 0; $i -lt $preamble.Length; $i++) {
                        if ($bytes[$i] -ne $preamble[$i]) {
                            $hasBom = $false
                            break
                        }
                    }
                    if ($hasBom) {
                        $encoding = New-Object System.Text.UTF8Encoding $true
                    }
                }
            }

            [System.IO.File]::WriteAllText($FilePath, $newContent, $encoding)
            return $true
        }
        catch {
            Write-ScriptMessage -Message "Failed to write to $FilePath : $($_.Exception.Message)" -IsError
            return $false
        }
    }
    else {
        Write-ScriptMessage -Message "Would add help to $functionName in $FilePath"
        Write-Host "  Function: $functionName" -ForegroundColor Yellow
        return $true
    }
}

# Process all PowerShell files
$totalFiles = 0
$totalFunctions = 0
$functionsAdded = 0
$filesModified = 0
$errors = 0

foreach ($scanPath in $pathsToScan) {
    if (-not (Test-Path -LiteralPath $scanPath)) {
        Write-ScriptMessage -Message "Skipping non-existent path: $scanPath" -IsWarning
        continue
    }

    $psFiles = Get-ChildItem -Path $scanPath -Filter '*.ps1' -File -Recurse | Where-Object {
        # Skip test files in certain directories if needed
        $_.FullName -notmatch '\\node_modules\\' -and
        $_.FullName -notmatch '\\\.git\\'
    } | Sort-Object FullName

    # Level 1: File processing start
    if ($debugLevel -ge 1) {
        Write-Verbose "[code-quality.add-comment-help] Processing $($psFiles.Count) PowerShell file(s)"
    }
    
    $processStartTime = Get-Date
    foreach ($psFile in $psFiles) {
        # Level 1: Individual file processing
        if ($debugLevel -ge 1) {
            Write-Verbose "[code-quality.add-comment-help] Processing file: $($psFile.Name)"
        }
        
        $fileStartTime = Get-Date
        $totalFiles++

        try {
            $content = Read-FileContent -Path $psFile.FullName
            if ([string]::IsNullOrWhiteSpace($content)) {
                continue
            }

            $ast = Get-PowerShellAst -Path $psFile.FullName
            $functionAsts = Get-FunctionsFromAst -Ast $ast

            $fileModified = $false
            foreach ($funcAst in $functionAsts) {
                $totalFunctions++

                # Skip functions with colons (internal/global functions)
                if ($funcAst.Name -match ':') {
                    continue
                }

                $hasHelp = Test-FunctionHasHelp -FuncAst $funcAst -Content $content -CheckBody

                if (-not $hasHelp -or $Force) {
                    $result = Add-CommentHelpToFunction -FilePath $psFile.FullName -FuncAst $funcAst -Content $content -DryRun:$DryRun -Force:$Force
                    if ($result) {
                        $functionsAdded++
                        $fileModified = $true

                        # Re-read content if we modified it (for subsequent functions in same file)
                        if (-not $DryRun) {
                            $content = Read-FileContent -Path $psFile.FullName
                            $ast = Get-PowerShellAst -Path $psFile.FullName
                        }
                    }
                }
            }

            if ($fileModified) {
                $filesModified++
            }
        }
        catch {
            $errors++
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to process file" -OperationName 'comment-help.add' -Context @{
                    file_path = $psFile.FullName
                } -Code 'FileProcessingFailed'
            }
            else {
                Write-ScriptMessage -Message "Error processing $($psFile.FullName): $($_.Exception.Message)" -IsWarning
            }
        }
    }
}

$processDuration = ((Get-Date) - $processStartTime).TotalMilliseconds

# Level 2: Overall processing timing
if ($debugLevel -ge 2) {
    Write-Verbose "[code-quality.add-comment-help] Processing completed in ${processDuration}ms"
    Write-Verbose "[code-quality.add-comment-help] Files: $totalFiles, Functions: $totalFunctions, Added: $functionsAdded, Modified: $filesModified, Errors: $errors"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $avgFileTime = if ($totalFiles -gt 0) { $processDuration / $totalFiles } else { 0 }
    $avgFuncTime = if ($totalFunctions -gt 0) { $processDuration / $totalFunctions } else { 0 }
    Write-Host "  [code-quality.add-comment-help] Performance - Duration: ${processDuration}ms, Avg per file: ${avgFileTime}ms, Avg per function: ${avgFuncTime}ms" -ForegroundColor DarkGray
}

# Summary
Write-ScriptMessage -Message "Processed $totalFiles files with $totalFunctions functions"
Write-ScriptMessage -Message "Added comment-based help to $functionsAdded functions in $filesModified files"
if ($errors -gt 0) {
    Write-ScriptMessage -Message "Encountered $errors errors" -IsWarning
}

if ($DryRun) {
    Write-ScriptMessage -Message "Dry run completed. Use without -DryRun to apply changes."
    Exit-WithCode -ExitCode [ExitCode]::Success
}
else {
    if ($functionsAdded -gt 0) {
        Exit-WithCode -ExitCode [ExitCode]::Success -Message "Successfully added comment-based help to $functionsAdded functions."
    }
    else {
        Exit-WithCode -ExitCode [ExitCode]::Success -Message "All functions already have comment-based help."
    }
}
