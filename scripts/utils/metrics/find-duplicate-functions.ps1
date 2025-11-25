<#
scripts/utils/find-duplicate-functions.ps1

.SYNOPSIS
    Finds duplicate function definitions in profile.d directory.

.DESCRIPTION
    Scans all PowerShell script files in the profile.d directory and identifies
    functions that are defined in multiple files. This helps detect potential conflicts
    or duplicate function definitions that could cause issues.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\find-duplicate-functions.ps1

    Scans profile.d directory and reports any duplicate function definitions.
#>

# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'RegexUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'FileContent' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Collections' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Parallel' -ScriptPath $PSScriptRoot -DisableNameChecking

# Get profile directory using shared function
try {
    $profileDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot
    Test-PathExists -Path $profileDir -PathType 'Directory'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$files = Get-PowerShellScripts -Path $profileDir -SortByName

# Use Collections module for better performance
$found = New-ObjectList

# Get compiled regex pattern from RegexUtilities module
$patterns = Get-CommonRegexPatterns
$functionRegex = $patterns['FunctionDefinition']

Write-ScriptMessage -Message "Scanning $($files.Count) file(s) for duplicate functions..."

# Process files in parallel for better performance
# Note: Invoke-Parallel uses Start-Job which runs in separate process, so we need to recreate regex in scriptblock
$functionRegexPattern = "function\s+([A-Za-z0-9_-]+)\s*\{"
$scanResults = Invoke-Parallel -Items $files -ScriptBlock {
    param($File)
    
    $fileFunctions = New-ObjectList
    
    try {
        $content = Read-FileContent -Path $File.FullName
        # Recreate regex in scriptblock since we can't pass compiled regex across process boundaries
        $functionRegex = [regex]::new($using:functionRegexPattern, [System.Text.RegularExpressions.RegexOptions]::Compiled)
        
        foreach ($match in $functionRegex.Matches($content)) {
            $fileFunctions.Add([PSCustomObject]@{
                    File = $File.FullName
                    Name = $match.Groups[1].Value
                })
        }
    }
    catch {
        Write-Warning "Failed to scan $($File.FullName): $($_.Exception.Message)"
    }
    
    return $fileFunctions.ToArray()
} -ThrottleLimit 5

# Collect results
foreach ($result in $scanResults) {
    if ($result) {
        $found.AddRange($result)
    }
}

$groups = $found | Group-Object Name | Where-Object { $_.Count -gt 1 }

if ($groups.Count -eq 0) {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "No duplicate function definitions found in profile.d"
}

foreach ($g in $groups) {
    Write-ScriptMessage -Message "Function: $($g.Name)"
    $g.Group | ForEach-Object { Write-ScriptMessage -Message "  - $($_.File)" }
    Write-ScriptMessage -Message ""
}

# Exit with validation failure if duplicates found (non-zero exit indicates issue)
Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Found $($groups.Count) duplicate function definition(s)"

