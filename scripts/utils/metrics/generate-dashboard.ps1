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

.PARAMETER DryRun
    If specified, shows what dashboard would be generated without actually creating the file.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\metrics\generate-dashboard.ps1

    Generates a metrics dashboard with current metrics.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\metrics\generate-dashboard.ps1 -IncludeHistorical

    Generates a dashboard with historical trend analysis.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\metrics\generate-dashboard.ps1 -DryRun

    Shows what dashboard would be generated without actually creating the file.
#>

param(
    [string]$OutputPath = $null,

    [switch]$IncludeHistorical,

    [string]$HistoricalDataPath = $null,

    [switch]$DryRun
)

# Import shared utilities directly (no barrel files)
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Parse debug level once at script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Import shared utilities using ModuleImport
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Locale' -ScriptPath $PSScriptRoot -DisableNameChecking
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
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.dashboard] Starting dashboard generation"
    Write-Verbose "[metrics.dashboard] Include historical: $IncludeHistorical, Historical data path: $HistoricalDataPath"
    Write-Verbose "[metrics.dashboard] Dry run: $DryRun"
}

Write-ScriptMessage -Message "Generating metrics dashboard..." -LogLevel Info

# Determine output path
if (-not $OutputPath) {
    $dataDir = Join-Path $repoRoot 'scripts' 'data'
    Ensure-DirectoryExists -Path $dataDir
    $OutputPath = Join-Path $dataDir 'metrics-dashboard.html'
}

# Level 1: Metrics loading start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.dashboard] Loading current metrics"
}

# Load current metrics
$loadStartTime = Get-Date
$metrics = Get-DashboardMetrics -RepoRoot $repoRoot
$codeMetrics = $metrics.CodeMetrics
$performanceMetrics = $metrics.PerformanceMetrics
$coverageTrends = $metrics.CoverageTrends
$loadDuration = ((Get-Date) - $loadStartTime).TotalMilliseconds

# Level 2: Metrics loading timing
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.dashboard] Metrics loaded in ${loadDuration}ms"
}

# Load historical data if requested
$historicalData = $null
if ($IncludeHistorical) {
    # Level 1: Historical data loading start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.dashboard] Loading historical data"
    }
    
    if (-not $HistoricalDataPath) {
        $HistoricalDataPath = Join-Path $repoRoot 'scripts' 'data' 'history'
    }
    
    $historyStartTime = Get-Date
    $historicalData = Get-DashboardHistoricalData -HistoricalDataPath $HistoricalDataPath
    $historyDuration = ((Get-Date) - $historyStartTime).TotalMilliseconds
    
    # Level 2: Historical data loading timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[metrics.dashboard] Historical data loaded in ${historyDuration}ms"
    }
}

# Level 1: HTML generation start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.dashboard] Generating HTML dashboard"
}

# Generate HTML dashboard
$htmlStartTime = Get-Date
$html = New-DashboardHtml -CodeMetrics $codeMetrics -PerformanceMetrics $performanceMetrics -CoverageTrends $coverageTrends -HistoricalData $historicalData -IncludeHistorical:$IncludeHistorical
$htmlDuration = ((Get-Date) - $htmlStartTime).TotalMilliseconds

# Level 2: HTML generation timing
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.dashboard] HTML dashboard generated in ${htmlDuration}ms"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $totalDuration = $loadDuration + $htmlDuration
    if ($IncludeHistorical) {
        $totalDuration += $historyDuration
    }
    Write-Host "  [metrics.dashboard] Performance - Load: ${loadDuration}ms, History: $(if ($IncludeHistorical) { "${historyDuration}ms" } else { "N/A" }), HTML: ${htmlDuration}ms, Total: ${totalDuration}ms" -ForegroundColor DarkGray
}

if ($DryRun) {
    Write-ScriptMessage -Message "[DRY RUN] Would generate dashboard at: $OutputPath" -ForegroundColor Yellow
    Write-ScriptMessage -Message "[DRY RUN] Dashboard would include:" -ForegroundColor Yellow
    Write-ScriptMessage -Message "  - Code metrics" -ForegroundColor Yellow
    Write-ScriptMessage -Message "  - Performance metrics" -ForegroundColor Yellow
    if ($IncludeHistorical) {
        Write-ScriptMessage -Message "  - Historical trend analysis" -ForegroundColor Yellow
    }
    Write-ScriptMessage -Message "Run without -DryRun to generate the dashboard." -ForegroundColor Yellow
    Exit-WithCode -ExitCode [ExitCode]::Success -Message "DRY RUN: Would generate dashboard at $OutputPath"
}

try {
    $html | Set-Content -Path $OutputPath -Encoding UTF8
    Write-ScriptMessage -Message "Dashboard generated successfully: $OutputPath" -LogLevel Info
    
    # Open dashboard in browser if on Windows
    if ($IsWindows -or $PSVersionTable.PSVersion.Major -lt 6) {
        Start-Process $OutputPath
    }
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -Message "Failed to generate dashboard: $($_.Exception.Message)" -ErrorRecord $_
}

Exit-WithCode -ExitCode [ExitCode]::Success
