<#
scripts/utils/metrics/generate-dashboard.ps1

.SYNOPSIS
    Generates an HTML dashboard for visualizing code and performance metrics.

.DESCRIPTION
    Creates an interactive HTML dashboard that displays:
    - Code metrics (files, lines, functions, complexity)
    - Performance metrics (startup times, fragment performance)
    - Historical trends (if historical data is available)
    - Visual charts and graphs

.PARAMETER OutputPath
    Path where the HTML dashboard will be saved. Defaults to scripts/data/metrics-dashboard.html

.PARAMETER IncludeHistorical
    If specified, includes historical trend analysis in the dashboard.

.PARAMETER HistoricalDataPath
    Path to directory containing historical metrics snapshots. Defaults to scripts/data/history

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\metrics\generate-dashboard.ps1

    Generates a metrics dashboard with current metrics.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\metrics\generate-dashboard.ps1 -IncludeHistorical

    Generates a dashboard with historical trend analysis.
#>

param(
    [string]$OutputPath = $null,

    [switch]$IncludeHistorical,

    [string]$HistoricalDataPath = $null
)

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'FileSystem' -ScriptPath $PSScriptRoot -DisableNameChecking

# Import dashboard modules
$modulesPath = Join-Path $PSScriptRoot 'modules'
Import-Module (Join-Path $modulesPath 'DashboardDataLoader.psm1') -DisableNameChecking -ErrorAction Stop
Import-Module (Join-Path $modulesPath 'DashboardTemplates.psm1') -DisableNameChecking -ErrorAction Stop

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-ScriptMessage -Message "Generating metrics dashboard..." -LogLevel Info

# Determine output path
if (-not $OutputPath) {
    $dataDir = Join-Path $repoRoot 'scripts' 'data'
    Ensure-DirectoryExists -Path $dataDir
    $OutputPath = Join-Path $dataDir 'metrics-dashboard.html'
}

# Load current metrics
$metrics = Get-DashboardMetrics -RepoRoot $repoRoot
$codeMetrics = $metrics.CodeMetrics
$performanceMetrics = $metrics.PerformanceMetrics
$coverageTrends = $metrics.CoverageTrends

# Load historical data if requested
$historicalData = $null
if ($IncludeHistorical) {
    if (-not $HistoricalDataPath) {
        $HistoricalDataPath = Join-Path $repoRoot 'scripts' 'data' 'history'
    }
    $historicalData = Get-DashboardHistoricalData -HistoricalDataPath $HistoricalDataPath
}

# Generate HTML dashboard
$html = New-DashboardHtml -CodeMetrics $codeMetrics -PerformanceMetrics $performanceMetrics -CoverageTrends $coverageTrends -HistoricalData $historicalData -IncludeHistorical:$IncludeHistorical

try {
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    Write-ScriptMessage -Message "Dashboard generated successfully: $OutputPath" -LogLevel Info
    
    # Open dashboard in browser if on Windows
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        Start-Process $OutputPath
    }
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message "Failed to generate dashboard: $($_.Exception.Message)" -ErrorRecord $_
}

Exit-WithCode -ExitCode $EXIT_SUCCESS
