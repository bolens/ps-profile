<#
scripts/utils/run-lint.ps1

.SYNOPSIS
    Runs PSScriptAnalyzer against profile.d and scripts directories.

.DESCRIPTION
    Installs PSScriptAnalyzer if not present, then runs it against profile.d and scripts
    directories. This matches the CI lint task behavior exactly. Reports are saved to
    scripts/data/psscriptanalyzer-report.json. Exits with error code 1 if any Error-level
    findings are detected.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-lint.ps1

    Runs PSScriptAnalyzer on all PowerShell files in profile.d and scripts directories.
#>

# Import PathResolution first (required for ModuleImport to work)
$scriptsDir = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
$pathResolutionPath = Join-Path $scriptsDir 'lib' 'PathResolution.psm1'
if (-not (Test-Path $pathResolutionPath)) {
    throw "PathResolution module not found at: $pathResolutionPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $pathResolutionPath -DisableNameChecking -ErrorAction Stop

# Import ModuleImport (bootstrap)
$moduleImportPath = Join-Path $scriptsDir 'lib' 'ModuleImport.psm1'
if (-not (Test-Path $moduleImportPath)) {
    throw "ModuleImport module not found at: $moduleImportPath. PSScriptRoot: $PSScriptRoot"
}
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Cache' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PathValidation' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'PowerShellDetection' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking -Global
Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking -Global

# Get repository root using shared function
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Analyze both profile.d and scripts directories, matching CI behavior
$paths = @(
    Join-Path $repoRoot 'profile.d'
    Join-Path $repoRoot 'scripts'
) | Where-Object { Test-Path $_ }

if (-not $paths) {
    Write-ScriptMessage -Message "No paths found to analyze"
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}

# Ensure PSScriptAnalyzer is available
try {
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

# Locate settings file if present
$settingsFile = Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
$settingsParam = @{}
if (Test-Path $settingsFile) {
    Write-ScriptMessage -Message "Using settings file: $settingsFile"
    $settingsParam['Settings'] = $settingsFile
}

# Run analysis matching CI behavior exactly
# Use List for better performance than array concatenation
$results = [System.Collections.Generic.List[object]]::new()
foreach ($p in $paths) {
    Write-ScriptMessage -Message "Analyzing $p"
    try {
        $r = Invoke-ScriptAnalyzer -Path $p -Recurse -Severity @('Error', 'Warning', 'Information') -Verbose @settingsParam
        if ($r) {
            $results.AddRange($r)
        }
    }
    catch {
        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to analyze $p`: $($_.Exception.Message)" -ErrorRecord $_
    }
}

# Save report to JSON (matching CI behavior)
$reportData = $results | ForEach-Object {
    [PSCustomObject]@{
        FilePath = $_.ScriptName
        RuleName = $_.RuleName
        Severity = $_.Severity
        Message  = $_.Message
        Line     = $_.Line
        Column   = $_.Column
    }
}
$dataDir = Join-Path $repoRoot 'scripts' 'data'
$out = Join-Path $dataDir 'psscriptanalyzer-report.json'
Write-JsonFile -Path $out -InputObject $reportData -Depth 5 -EnsureDirectory
Write-ScriptMessage -Message "Saved report to $out"

# Fail if any Error-level findings (matching CI behavior)
$errorFindings = $results | Where-Object { $_.Severity -eq 'Error' }
if ($errorFindings) {
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Errors found by PSScriptAnalyzer"
}

Exit-WithCode -ExitCode $EXIT_SUCCESS -Message "PSScriptAnalyzer: no issues found"

