<#
scripts/utils/metrics/find-duplicate-functions.ps1

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

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Get profile directory using shared function
try {
    $profileDir = Get-ProfileDirectory -ScriptPath $PSScriptRoot
    Test-PathExists -Path $profileDir -PathType 'Directory'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

$files = Get-PowerShellScripts -Path $profileDir -SortByName

# Regex that skips optional 'global:' scope qualifier on function names
$functionRegex = [regex]::new(
    '^\s*function\s+(?:global:)?([A-Za-z][A-Za-z0-9_-]+)',
    [System.Text.RegularExpressions.RegexOptions]::Compiled -bor
    [System.Text.RegularExpressions.RegexOptions]::Multiline
)

if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.find-duplicates] Starting duplicate function detection"
    Write-Verbose "[metrics.find-duplicates] Files to scan: $($files.Count)"
}

Write-ScriptMessage -Message "Scanning $($files.Count) file(s) for duplicate functions..."

$found = [System.Collections.Generic.List[PSCustomObject]]::new()

$scanStart = [System.Diagnostics.Stopwatch]::StartNew()

foreach ($file in $files) {
    try {
        $content = [System.IO.File]::ReadAllText($file.FullName)
        foreach ($match in $functionRegex.Matches($content)) {
            $found.Add([PSCustomObject]@{
                File = $file.FullName
                Name = $match.Groups[1].Value
            })
        }
    }
    catch {
        Write-Warning "Failed to scan $($file.FullName): $($_.Exception.Message)"
    }
}

$scanMs = $scanStart.ElapsedMilliseconds

if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.find-duplicates] Scan completed in ${scanMs}ms, found $($found.Count) definitions"
}

$groups = $found | Group-Object Name | Where-Object { $_.Count -gt 1 }

if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.find-duplicates] Duplicate groups: $($groups.Count)"
}

if ($groups.Count -eq 0) {
    Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "No duplicate function definitions found in profile.d"
}

foreach ($g in $groups) {
    Write-ScriptMessage -Message "Function: $($g.Name)"
    $g.Group | ForEach-Object { Write-ScriptMessage -Message "  - $($_.File)" }
    Write-ScriptMessage -Message ""
}

Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Found $($groups.Count) duplicate function definition(s)"
