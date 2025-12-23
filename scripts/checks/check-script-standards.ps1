<#
scripts/checks/check-script-standards.ps1

.SYNOPSIS
    Validates that utility scripts follow codebase standards.

.DESCRIPTION
    Checks utility scripts for compliance with codebase standards:
    - Consistent Common.psm1 import patterns
    - Use of Exit-WithCode instead of direct exit calls
    - Proper error handling with try-catch blocks
    - Parameter validation patterns

.PARAMETER Path
    The path to check. Defaults to scripts directory relative to repository root.

.EXAMPLE
    pwsh -NoProfile -File scripts\checks\check-script-standards.ps1

    Validates all scripts in the scripts directory.
#>

param(
    [ValidateScript({
            if ($_ -and -not [string]::IsNullOrWhiteSpace($_) -and -not (Test-Path -LiteralPath $_)) {
                throw "Path does not exist: $_"
            }
            $true
        })]
    [string]$Path = $null
)

# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathValidation' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'RegexUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'FileContent' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Collections' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'FileFiltering' -ScriptPath $PSScriptRoot -DisableNameChecking

# Default to scripts directory relative to repository root
if (-not $Path) {
    try {
        $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
        $Path = Join-Path $repoRoot 'scripts'
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
    }
}

Write-ScriptMessage -Message "Checking script standards in: $Path"

# Use Collections module for better performance
$issues = New-ObjectList

# Get compiled regex patterns from RegexUtilities module
$patterns = Get-CommonRegexPatterns
$exitPattern = $patterns['ExitCall']
$exitVariablePattern = $patterns['ExitVariable']
$commonImportPattern = $patterns['ImportModule']

# Get all PowerShell scripts using helper function and filter with FileFiltering module
$allScripts = Get-PowerShellScripts -Path $Path -Recurse
$scripts = $allScripts | Filter-Files -ExcludeTests -ExcludeGit -ExcludeNames 'Common.psm1'

foreach ($script in $scripts) {
    $content = Read-FileContent -Path $script.FullName
    if (-not $content) { continue }

    # Use PathUtilities module for relative path calculation
    $relativePath = Get-RelativePath -From $Path -To $script.FullName

    # Check 1: Direct exit calls (excluding exit 0/1 in generated hook scripts)
    $exitMatches = $exitPattern.Matches($content)
    foreach ($match in $exitMatches) {
        $exitCode = $match.Groups[1].Value
        # Allow exit 0/1 in git hook templates (they're generating shell scripts)
        if ($script.FullName -match 'install.*hook' -and ($exitCode -eq '0' -or $exitCode -eq '1')) {
            # Check if it's in a here-string (template generation)
            $lineNum = ($content.Substring(0, $match.Index) -split "`n").Count
            $context = ($content -split "`n")[$lineNum - 1]
            if ($context -match '@"|@"|@''|@''') {
                continue  # It's in a template string, which is OK
            }
        }
        
        $issues.Add([PSCustomObject]@{
                File     = $relativePath
                Line     = ($content.Substring(0, $match.Index) -split "`n").Count
                Issue    = 'Direct exit call'
                Message  = "Found 'exit $exitCode' - use Exit-WithCode instead"
                Severity = 'Warning'
            })
    }

    # Check 2: Common.psm1 import pattern consistency
    # Scripts in scripts/utils/ should use: Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
    # Scripts in scripts/checks/ should use: Join-Path (Split-Path -Parent $PSScriptRoot) 'lib' 'Common.psm1'
    # Scripts in scripts/git/ should use: Join-Path $scriptsDir 'lib' 'Common.psm1'
    if ($commonImportPattern.IsMatch($content)) {
        $isInUtils = $script.FullName -match '[\\/]utils[\\/]'
        $isInChecks = $script.FullName -match '[\\/]checks[\\/]'
        $isInGit = $script.FullName -match '[\\/]git[\\/]'

        if ($isInUtils -and $content -notmatch "Join-Path\s+\(Split-Path\s+-Parent\s+`\$PSScriptRoot\)\s+['\`"]lib['\`"]\s+['\`"]Common\.psm1['\`"]") {
            $issues.Add([PSCustomObject]@{
                    File     = $relativePath
                    Line     = 0
                    Issue    = 'Inconsistent Common.psm1 import'
                    Message  = "Scripts in utils/ should use: Join-Path (Split-Path -Parent `$PSScriptRoot) 'lib' 'Common.psm1'"
                    Severity = 'Info'
                })
        }
        elseif ($isInChecks -and $content -notmatch "Join-Path\s+\(Split-Path\s+-Parent\s+`\$PSScriptRoot\)\s+['\`"]lib['\`"]\s+['\`"]Common\.psm1['\`"]") {
            $issues.Add([PSCustomObject]@{
                    File     = $relativePath
                    Line     = 0
                    Issue    = 'Inconsistent Common.psm1 import'
                    Message  = "Scripts in checks/ should use: Join-Path (Split-Path -Parent `$PSScriptRoot) 'lib' 'Common.psm1'"
                    Severity = 'Info'
                })
        }
        elseif ($isInGit -and $content -notmatch "Join-Path\s+`\$scriptsDir\s+['\`"]lib['\`"]\s+['\`"]Common\.psm1['\`"]") {
            # Git scripts use a different pattern, check for it
            if ($content -notmatch '`\$scriptsDir\s*=\s*Split-Path\s+-Parent\s+`\$PSScriptRoot') {
                $issues.Add([PSCustomObject]@{
                        File     = $relativePath
                        Line     = 0
                        Issue    = 'Inconsistent Common.psm1 import'
                        Message  = "Scripts in git/ should use: `$scriptsDir = Split-Path -Parent `$PSScriptRoot; Join-Path `$scriptsDir 'lib' 'Common.psm1'"
                        Severity = 'Info'
                    })
            }
        }
    }
    else {
        # Script doesn't import Common.psm1 - might be intentional, but flag it
        $issues.Add([PSCustomObject]@{
                File     = $relativePath
                Line     = 0
                Issue    = 'Missing Common.psm1 import'
                Message  = "Script does not import Common.psm1 - ensure this is intentional"
                Severity = 'Info'
            })
    }

    # Check 3: Error handling - scripts should wrap risky operations in try-catch
    # This is a heuristic check - look for operations that commonly need error handling
    $riskyOperations = @('Get-RepoRoot', 'Ensure-ModuleAvailable', 'Test-Path', 'Get-Content', 'Set-Content')
    foreach ($operation in $riskyOperations) {
        if (-not ($content -match "\b$operation\b" -and $content -notmatch "try\s*\{[\s\S]*?\b$operation\b")) {
            continue
        }
        
        # Check if it's already in a try-catch block (simplified check)
        $operationMatches = [regex]::Matches($content, "\b$operation\b")
        foreach ($opMatch in $operationMatches) {
            $beforeMatch = $content.Substring(0, $opMatch.Index)
            $tryCount = ([regex]::Matches($beforeMatch, '\btry\s*\{')).Count
            $catchCount = ([regex]::Matches($beforeMatch, '\bcatch\s*\{')).Count
            if ($tryCount -ne $catchCount) {
                continue
            }
            
            # Not in a try-catch block
            $issues.Add([PSCustomObject]@{
                    File     = $relativePath
                    Line     = ($content.Substring(0, $opMatch.Index) -split "`n").Count
                    Issue    = 'Missing error handling'
                    Message  = "Consider wrapping '$operation' in try-catch block"
                    Severity = 'Info'
                })
            break  # Only flag once per script
        }
    }
}

# Report results
if ($issues.Count -gt 0) {
    Write-ScriptMessage -Message "`nFound $($issues.Count) issue(s):"
    
    # Group by severity
    $errors = $issues | Where-Object { $_.Severity -eq 'Error' }
    $warnings = $issues | Where-Object { $_.Severity -eq 'Warning' }
    $info = $issues | Where-Object { $_.Severity -eq 'Info' }
    
    if ($errors.Count -gt 0) {
        Write-ScriptMessage -Message "`nErrors:" -ForegroundColor Red
        $errors | Format-Table -AutoSize
    }
    
    if ($warnings.Count -gt 0) {
        Write-ScriptMessage -Message "`nWarnings:" -ForegroundColor Yellow
        $warnings | Format-Table -AutoSize
    }
    
    if ($info.Count -gt 0) {
        Write-ScriptMessage -Message "`nInfo:" -ForegroundColor Cyan
        $info | Format-Table -AutoSize
    }
    
    # Exit with validation failure if there are errors or warnings
    if ($errors.Count -gt 0 -or $warnings.Count -gt 0) {
        Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Found $($errors.Count + $warnings.Count) issue(s) that need attention"
    }
    else {
        Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "Found $($info.Count) informational issue(s) - no action required"
    }
}
else {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "All scripts comply with codebase standards"
}


