<#
scripts/utils/metrics/track-coverage-trends.ps1

.SYNOPSIS
    Tracks test coverage trends over time by analyzing historical coverage data.

.DESCRIPTION
    Collects current test coverage metrics and compares them with historical data
    to identify trends. Saves coverage snapshots for trend analysis.

.PARAMETER CoverageXmlPath
    Path to the current Pester coverage.xml file. If not specified, searches common locations.

.PARAMETER HistoryPath
    Directory containing historical coverage snapshots. Defaults to scripts/data/coverage-history.

.PARAMETER SaveSnapshot
    If specified, saves current coverage as a snapshot for future trend analysis.

.PARAMETER Days
    Number of days of history to analyze. Default: 30.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\metrics\track-coverage-trends.ps1

    Analyzes coverage trends from the last 30 days.

.EXAMPLE
    pwsh -NoProfile -File scripts\utils\metrics\track-coverage-trends.ps1 -SaveSnapshot -Days 60

    Saves current coverage snapshot and analyzes trends from the last 60 days.
#>

param(
    [string]$CoverageXmlPath = $null,

    [string]$HistoryPath = $null,

    [switch]$SaveSnapshot,

    [int]$Days = 30
)

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'Common.psm1'
Import-Module $commonModulePath -ErrorAction Stop

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}

Write-ScriptMessage -Message "Tracking test coverage trends..." -LogLevel Info

# Find coverage file
if (-not $CoverageXmlPath) {
    $possibleCoveragePaths = @(
        Join-Path $repoRoot 'coverage.xml'
        Join-Path $repoRoot 'scripts' 'data' 'coverage.xml'
    )
    
    foreach ($path in $possibleCoveragePaths) {
        if (Test-Path -Path $path) {
            $CoverageXmlPath = $path
            break
        }
    }
}

if (-not $CoverageXmlPath -or -not (Test-Path -Path $CoverageXmlPath)) {
    Write-ScriptMessage -Message "Coverage file not found. Run tests with coverage first." -IsWarning
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}

# Get current coverage
$currentCoverage = Get-TestCoverage -CoverageXmlPath $CoverageXmlPath

if ($currentCoverage.Error) {
    Write-ScriptMessage -Message "Failed to parse coverage: $($currentCoverage.Error)" -IsWarning
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}

Write-ScriptMessage -Message "Current Coverage: $($currentCoverage.CoveragePercent)%" -LogLevel Info
Write-ScriptMessage -Message "  Covered Lines: $($currentCoverage.CoveredLines) / $($currentCoverage.TotalLines)" -LogLevel Info

# Set up history directory
if (-not $HistoryPath) {
    $HistoryPath = Join-Path $repoRoot 'scripts' 'data' 'coverage-history'
}

Ensure-DirectoryExists -Path $HistoryPath

# Save snapshot if requested
if ($SaveSnapshot) {
    $snapshotFile = Join-Path $HistoryPath "coverage-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    try {
        $currentCoverage | ConvertTo-Json -Depth 10 | Set-Content -Path $snapshotFile -Encoding UTF8
        Write-ScriptMessage -Message "Coverage snapshot saved: $snapshotFile" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Failed to save snapshot: $($_.Exception.Message)" -IsWarning
    }
}

# Load historical data
$cutoffDate = (Get-Date).AddDays(-$Days)
$historicalFiles = Get-ChildItem -Path $HistoryPath -Filter 'coverage-*.json' | 
Where-Object { $_.LastWriteTime -ge $cutoffDate } | 
Sort-Object LastWriteTime

if ($historicalFiles.Count -eq 0) {
    Write-ScriptMessage -Message "No historical coverage data found in the last $Days days." -LogLevel Info
    Write-ScriptMessage -Message "Run with -SaveSnapshot to start tracking trends." -LogLevel Info
    Exit-WithCode -ExitCode $EXIT_SUCCESS
}

Write-ScriptMessage -Message "`nAnalyzing $($historicalFiles.Count) historical snapshots..." -LogLevel Info

# Load and analyze historical data
$historicalData = [System.Collections.Generic.List[PSCustomObject]]::new()
foreach ($file in $historicalFiles) {
    try {
        $data = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
        $historicalData.Add([PSCustomObject]@{
                Timestamp       = $data.Timestamp
                Date            = [DateTime]::Parse($data.Timestamp)
                CoveragePercent = $data.CoveragePercent
                TotalLines      = $data.TotalLines
                CoveredLines    = $data.CoveredLines
            })
    }
    catch {
        Write-ScriptMessage -Message "Failed to load $($file.Name): $($_.Exception.Message)" -IsWarning
    }
}

# Add current data
$historicalData.Add([PSCustomObject]@{
        Timestamp       = $currentCoverage.Timestamp
        Date            = [DateTime]::Parse($currentCoverage.Timestamp)
        CoveragePercent = $currentCoverage.CoveragePercent
        TotalLines      = $currentCoverage.TotalLines
        CoveredLines    = $currentCoverage.CoveredLines
    })

# Sort by date
$historicalData = $historicalData | Sort-Object Date

# Calculate trends
$first = $historicalData[0]
$last = $historicalData[-1]
$coverageChange = $last.CoveragePercent - $first.CoveragePercent
$linesChange = $last.TotalLines - $first.TotalLines
$coveredLinesChange = $last.CoveredLines - $first.CoveredLines

Write-ScriptMessage -Message "`nCoverage Trends (last $Days days):" -LogLevel Info
Write-ScriptMessage -Message "  Period: $($first.Date.ToString('yyyy-MM-dd')) to $($last.Date.ToString('yyyy-MM-dd'))" -LogLevel Info
Write-ScriptMessage -Message "  Coverage Change: $([math]::Round($coverageChange, 2))% ($(if ($coverageChange -ge 0) { '+' } else { '' })$([math]::Round($coverageChange, 2))%)" -LogLevel Info
Write-ScriptMessage -Message "  Total Lines Change: $linesChange ($(if ($linesChange -ge 0) { '+' } else { '' })$linesChange)" -LogLevel Info
Write-ScriptMessage -Message "  Covered Lines Change: $coveredLinesChange ($(if ($coveredLinesChange -ge 0) { '+' } else { '' })$coveredLinesChange)" -LogLevel Info

# Calculate average coverage
$avgCoverage = ($historicalData | Measure-Object -Property CoveragePercent -Average).Average
Write-ScriptMessage -Message "  Average Coverage: $([math]::Round($avgCoverage, 2))%" -LogLevel Info

# Determine trend direction
if ($coverageChange -gt 1) {
    Write-ScriptMessage -Message "`nTrend: 📈 Improving coverage" -LogLevel Info
}
elseif ($coverageChange -lt -1) {
    Write-ScriptMessage -Message "`nTrend: 📉 Declining coverage" -IsWarning
}
else {
    Write-ScriptMessage -Message "`nTrend: ➡️ Stable coverage" -LogLevel Info
}

# Save trend summary
$trendSummary = [PSCustomObject]@{
    Timestamp          = [DateTime]::UtcNow.ToString('o')
    PeriodDays         = $Days
    FirstDate          = $first.Date.ToString('o')
    LastDate           = $last.Date.ToString('o')
    FirstCoverage      = $first.CoveragePercent
    LastCoverage       = $last.CoveragePercent
    CoverageChange     = [math]::Round($coverageChange, 2)
    AverageCoverage    = [math]::Round($avgCoverage, 2)
    TotalLinesChange   = $linesChange
    CoveredLinesChange = $coveredLinesChange
    DataPoints         = $historicalData.Count
    HistoricalData     = $historicalData.ToArray()
}

$trendFile = Join-Path $repoRoot 'scripts' 'data' 'coverage-trends.json'
try {
    $trendSummary | ConvertTo-Json -Depth 10 | Set-Content -Path $trendFile -Encoding UTF8
    Write-ScriptMessage -Message "`nTrend summary saved: $trendFile" -LogLevel Info
}
catch {
    Write-ScriptMessage -Message "Failed to save trend summary: $($_.Exception.Message)" -IsWarning
}

Exit-WithCode -ExitCode $EXIT_SUCCESS

