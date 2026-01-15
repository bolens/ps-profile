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
Import-LibModule -ModuleName 'JsonUtilities' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Collections' -ScriptPath $PSScriptRoot -DisableNameChecking

# Get repository root
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
}
catch {
    Exit-WithCode -ExitCode [ExitCode]::SetupError -ErrorRecord $_
}

# Level 1: Basic operation start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.track-coverage] Starting coverage trend tracking"
    Write-Verbose "[metrics.track-coverage] Coverage XML path: $CoverageXmlPath, History path: $HistoryPath"
    Write-Verbose "[metrics.track-coverage] Save snapshot: $SaveSnapshot, Days: $Days"
}

Write-ScriptMessage -Message "Tracking test coverage trends..." -LogLevel Info

# Find coverage file
if (-not $CoverageXmlPath) {
    # Level 1: Coverage file discovery
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.track-coverage] Searching for coverage XML file"
    }
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
    Exit-WithCode -ExitCode [ExitCode]::Success
}

# Level 1: Coverage parsing start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.track-coverage] Parsing current coverage from: $CoverageXmlPath"
}

# Get current coverage
$coverageStartTime = Get-Date
$currentCoverage = Get-TestCoverage -CoverageXmlPath $CoverageXmlPath
$coverageDuration = ((Get-Date) - $coverageStartTime).TotalMilliseconds

# Level 2: Coverage parsing timing
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.track-coverage] Coverage parsed in ${coverageDuration}ms"
}

if ($currentCoverage.Error) {
    Write-ScriptMessage -Message "Failed to parse coverage: $($currentCoverage.Error)" -IsWarning
    Exit-WithCode -ExitCode [ExitCode]::Success
}

$coveragePercentStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber $currentCoverage.CoveragePercent -Format 'N2'
}
else {
    $currentCoverage.CoveragePercent.ToString("N2")
}
Write-ScriptMessage -Message "Current Coverage: ${coveragePercentStr}%" -LogLevel Info
Write-ScriptMessage -Message "  Covered Lines: $($currentCoverage.CoveredLines) / $($currentCoverage.TotalLines)" -LogLevel Info

# Set up history directory
if (-not $HistoryPath) {
    $HistoryPath = Join-Path $repoRoot 'scripts' 'data' 'coverage-history'
}

Ensure-DirectoryExists -Path $HistoryPath

# Save snapshot if requested
if ($SaveSnapshot) {
    # Level 1: Snapshot save start
    if ($debugLevel -ge 1) {
        Write-Verbose "[metrics.track-coverage] Saving coverage snapshot"
    }
    
    $snapshotFile = Join-Path $HistoryPath "coverage-$(Get-Date -Format 'yyyyMMdd-HHmmss').json"
    $snapshotStartTime = Get-Date
    try {
        Write-JsonFile -Path $snapshotFile -InputObject $currentCoverage -Depth 10 -EnsureDirectory
        $snapshotDuration = ((Get-Date) - $snapshotStartTime).TotalMilliseconds
        
        Write-ScriptMessage -Message "Coverage snapshot saved: $snapshotFile" -LogLevel Info
        
        # Level 2: Snapshot save timing
        if ($debugLevel -ge 2) {
            Write-Verbose "[metrics.track-coverage] Snapshot saved in ${snapshotDuration}ms"
        }
    }
    catch {
        Write-ScriptMessage -Message "Failed to save snapshot: $($_.Exception.Message)" -IsWarning
    }
}

# Level 1: Historical data loading start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.track-coverage] Loading historical coverage data"
}

# Load historical data
$cutoffDate = (Get-Date).AddDays(-$Days)
$historyStartTime = Get-Date
$historicalFiles = Get-ChildItem -Path $HistoryPath -Filter 'coverage-*.json' | 
Where-Object { $_.LastWriteTime -ge $cutoffDate } | 
Sort-Object LastWriteTime
$historyDuration = ((Get-Date) - $historyStartTime).TotalMilliseconds

# Level 2: Historical file discovery timing
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.track-coverage] Historical file discovery completed in ${historyDuration}ms"
    Write-Verbose "[metrics.track-coverage] Found $($historicalFiles.Count) historical snapshot(s)"
}

if ($historicalFiles.Count -eq 0) {
    Write-ScriptMessage -Message "No historical coverage data found in the last $Days days." -LogLevel Info
    Write-ScriptMessage -Message "Run with -SaveSnapshot to start tracking trends." -LogLevel Info
    Exit-WithCode -ExitCode [ExitCode]::Success
}

Write-ScriptMessage -Message "`nAnalyzing $($historicalFiles.Count) historical snapshots..." -LogLevel Info

# Level 1: Historical data analysis start
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.track-coverage] Analyzing historical coverage data"
}

# Load and analyze historical data
$historicalData = New-ObjectList
$analysisStartTime = Get-Date
foreach ($file in $historicalFiles) {
    try {
        $data = Read-JsonFile -Path $file.FullName -ErrorAction SilentlyContinue
        if ($null -eq $data) { continue }
        $historicalData.Add([PSCustomObject]@{
                Timestamp       = $data.Timestamp
                Date            = [DateTime]::Parse($data.Timestamp)
                CoveragePercent = $data.CoveragePercent
                TotalLines      = $data.TotalLines
                CoveredLines    = $data.CoveredLines
            })
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to load historical coverage snapshot" -OperationName 'metrics.track-coverage.load-history' -Context @{
                file_name = $file.Name
                file_path = $file.FullName
            } -Code 'HistoryLoadFailed'
        }
        else {
            Write-ScriptMessage -Message "Failed to load $($file.Name): $($_.Exception.Message)" -IsWarning
        }
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

$analysisDuration = ((Get-Date) - $analysisStartTime).TotalMilliseconds

# Level 2: Historical data analysis timing
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.track-coverage] Historical data analysis completed in ${analysisDuration}ms"
    Write-Verbose "[metrics.track-coverage] Historical data points: $($historicalData.Count)"
}

# Calculate trends
$trendStartTime = Get-Date
$first = $historicalData[0]
$last = $historicalData[-1]
$coverageChange = $last.CoveragePercent - $first.CoveragePercent
$linesChange = $last.TotalLines - $first.TotalLines
$coveredLinesChange = $last.CoveredLines - $first.CoveredLines
$trendDuration = ((Get-Date) - $trendStartTime).TotalMilliseconds

# Level 2: Trend calculation timing
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.track-coverage] Trend calculation completed in ${trendDuration}ms"
}

Write-ScriptMessage -Message "`nCoverage Trends (last $Days days):" -LogLevel Info

# Use locale-aware date formatting for user-facing dates
$firstDateStr = if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
    Format-LocaleDate $first.Date -Format 'yyyy-MM-dd'
}
else {
    $first.Date.ToString('yyyy-MM-dd')
}
$lastDateStr = if (Get-Command Format-LocaleDate -ErrorAction SilentlyContinue) {
    Format-LocaleDate $last.Date -Format 'yyyy-MM-dd'
}
else {
    $last.Date.ToString('yyyy-MM-dd')
}
Write-ScriptMessage -Message "  Period: $firstDateStr to $lastDateStr" -LogLevel Info
$coverageChangeStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([math]::Round($coverageChange, 2)) -Format 'N2'
}
else {
    [math]::Round($coverageChange, 2).ToString("N2")
}
$coverageChangeSignedStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([math]::Round($coverageChange, 2)) -Format 'N2'
}
else {
    [math]::Round($coverageChange, 2).ToString("N2")
}
Write-ScriptMessage -Message "  Coverage Change: ${coverageChangeStr}% ($(if ($coverageChange -ge 0) { '+' } else { '' })${coverageChangeSignedStr}%)" -LogLevel Info
Write-ScriptMessage -Message "  Total Lines Change: $linesChange ($(if ($linesChange -ge 0) { '+' } else { '' })$linesChange)" -LogLevel Info
Write-ScriptMessage -Message "  Covered Lines Change: $coveredLinesChange ($(if ($coveredLinesChange -ge 0) { '+' } else { '' })$coveredLinesChange)" -LogLevel Info

# Calculate average coverage
$avgCoverage = ($historicalData | Measure-Object -Property CoveragePercent -Average).Average
$avgCoverageStr = if (Get-Command Format-LocaleNumber -ErrorAction SilentlyContinue) {
    Format-LocaleNumber ([math]::Round($avgCoverage, 2)) -Format 'N2'
}
else {
    [math]::Round($avgCoverage, 2).ToString("N2")
}
Write-ScriptMessage -Message "  Average Coverage: ${avgCoverageStr}%" -LogLevel Info

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

# Level 1: Trend summary generation
if ($debugLevel -ge 1) {
    Write-Verbose "[metrics.track-coverage] Generating trend summary"
}

# Save trend summary
$summaryStartTime = Get-Date
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
$summarySaveStartTime = Get-Date
try {
    Write-JsonFile -Path $trendFile -InputObject $trendSummary -Depth 10 -EnsureDirectory
    $summarySaveDuration = ((Get-Date) - $summarySaveStartTime).TotalMilliseconds
    
    Write-ScriptMessage -Message "`nTrend summary saved: $trendFile" -LogLevel Info
    
    # Level 2: Summary save timing
    if ($debugLevel -ge 2) {
        Write-Verbose "[metrics.track-coverage] Trend summary saved in ${summarySaveDuration}ms"
    }
}
catch {
    Write-ScriptMessage -Message "Failed to save trend summary: $($_.Exception.Message)" -IsWarning
}

$summaryDuration = ((Get-Date) - $summaryStartTime).TotalMilliseconds

# Level 2: Overall summary timing
if ($debugLevel -ge 2) {
    Write-Verbose "[metrics.track-coverage] Trend summary generation completed in ${summaryDuration}ms"
}

# Level 3: Performance breakdown
if ($debugLevel -ge 3) {
    $totalDuration = $coverageDuration + $historyDuration + $analysisDuration + $trendDuration + $summaryDuration
    Write-Host "  [metrics.track-coverage] Performance - Parse: ${coverageDuration}ms, History: ${historyDuration}ms, Analysis: ${analysisDuration}ms, Trend: ${trendDuration}ms, Summary: ${summaryDuration}ms, Total: ${totalDuration}ms" -ForegroundColor DarkGray
}

Exit-WithCode -ExitCode [ExitCode]::Success
