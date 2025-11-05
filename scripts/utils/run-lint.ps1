<#
scripts/utils/run-lint.ps1

.SYNOPSIS
    Runs PSScriptAnalyzer against profile.d and scripts directories.

.DESCRIPTION
    Installs PSScriptAnalyzer if not present, then runs it against profile.d and scripts
    directories. This matches the CI lint task behavior exactly. Reports are saved to
    psscriptanalyzer-report.json. Exits with error code 1 if any Error-level findings
    are detected.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\run-lint.ps1

    Runs PSScriptAnalyzer on all PowerShell files in profile.d and scripts directories.
#>

# Cache path calculations once
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Definition
$repoRoot = Split-Path -Parent (Split-Path -Parent $scriptDir)

# Analyze both profile.d and scripts directories, matching CI behavior
$paths = @(
    Join-Path $repoRoot 'profile.d'
    Join-Path $repoRoot 'scripts'
) | Where-Object { Test-Path $_ }

if (-not $paths) {
    Write-Output "No paths found to analyze"
    exit 0
}



# Ensure module is available in current user scope
if (-not (Get-Module -ListAvailable -Name PSScriptAnalyzer)) {
    Write-Output "PSScriptAnalyzer not found. Installing to CurrentUser scope..."
    try {
        Install-Module -Name PSScriptAnalyzer -Scope CurrentUser -Force -Confirm:$false -ErrorAction Stop
    }
    catch {
        Write-Error "Failed to install PSScriptAnalyzer: $($_.Exception.Message)"
        exit 2
    }
}

# Import PSScriptAnalyzer module
Import-Module -Name PSScriptAnalyzer -Force -ErrorAction Stop

# Locate settings file if present
$settingsFile = Join-Path $repoRoot 'PSScriptAnalyzerSettings.psd1'
$settingsParam = @{}
if (Test-Path $settingsFile) {
    Write-Output "Using settings file: $settingsFile"
    $settingsParam['Settings'] = $settingsFile
}

# Run analysis matching CI behavior exactly
$results = @()
foreach ($p in $paths) {
    Write-Output "Analyzing $p"
    $r = Invoke-ScriptAnalyzer -Path $p -Recurse -Severity @('Error', 'Warning', 'Information') -Verbose @settingsParam
    $results += $r
}

# Save report to JSON (matching CI behavior)
$json = $results | Select-Object @{n = 'FilePath'; e = { $_.ScriptName } }, RuleName, Severity, Message, Line, Column | ConvertTo-Json -Depth 5
$out = "psscriptanalyzer-report.json"
$json | Out-File -FilePath $out -Encoding utf8
Write-Output "Saved report to $out"

# Fail if any Error-level findings (matching CI behavior)
if ($results | Where-Object { $_.Severity -eq 'Error' }) {
    Write-Output "Errors found by PSScriptAnalyzer"
    exit 1
}

Write-Output "PSScriptAnalyzer: no issues found"
exit 0
