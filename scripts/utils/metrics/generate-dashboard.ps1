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

# Import shared utilities
$commonModulePath = Join-Path (Split-Path -Parent (Split-Path -Parent (Split-Path -Parent $PSScriptRoot))) 'lib' 'Common.psm1'
Import-Module $commonModulePath -DisableNameChecking -ErrorAction Stop

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
$codeMetricsFile = Join-Path $repoRoot 'scripts' 'data' 'code-metrics.json'
$performanceBaselineFile = Join-Path $repoRoot 'scripts' 'data' 'performance-baseline.json'
$coverageTrendsFile = Join-Path $repoRoot 'scripts' 'data' 'coverage-trends.json'

$codeMetrics = $null
$performanceMetrics = $null
$coverageTrends = $null

if (Test-Path -Path $codeMetricsFile) {
    try {
        $codeMetrics = Get-Content -Path $codeMetricsFile -Raw | ConvertFrom-Json
        Write-ScriptMessage -Message "Loaded code metrics" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Failed to load code metrics: $($_.Exception.Message)" -IsWarning
    }
}

if (Test-Path -Path $performanceBaselineFile) {
    try {
        $performanceMetrics = Get-Content -Path $performanceBaselineFile -Raw | ConvertFrom-Json
        Write-ScriptMessage -Message "Loaded performance metrics" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Failed to load performance metrics: $($_.Exception.Message)" -IsWarning
    }
}

if (Test-Path -Path $coverageTrendsFile) {
    try {
        $coverageTrends = Get-Content -Path $coverageTrendsFile -Raw | ConvertFrom-Json
        Write-ScriptMessage -Message "Loaded coverage trends" -LogLevel Info
    }
    catch {
        Write-ScriptMessage -Message "Failed to load coverage trends: $($_.Exception.Message)" -IsWarning
    }
}

# Load historical data if requested
$historicalData = $null
if ($IncludeHistorical) {
    if (-not $HistoricalDataPath) {
        $HistoricalDataPath = Join-Path $repoRoot 'scripts' 'data' 'history'
    }
    
    if (Test-Path -Path $HistoricalDataPath) {
        try {
            $historicalFiles = Get-ChildItem -Path $HistoricalDataPath -Filter 'metrics-*.json' | Sort-Object LastWriteTime
            $historicalData = @()
            
            foreach ($file in $historicalFiles) {
                try {
                    $data = Get-Content -Path $file.FullName -Raw | ConvertFrom-Json
                    $historicalData += $data
                }
                catch {
                    Write-ScriptMessage -Message "Failed to load historical file $($file.Name): $($_.Exception.Message)" -IsWarning
                }
            }
            
            Write-ScriptMessage -Message "Loaded $($historicalData.Count) historical snapshots" -LogLevel Info
        }
        catch {
            Write-ScriptMessage -Message "Failed to load historical data: $($_.Exception.Message)" -IsWarning
        }
    }
    else {
        Write-ScriptMessage -Message "Historical data directory not found: $HistoricalDataPath" -IsWarning
    }
}

# Generate HTML dashboard
$html = @"
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>PowerShell Profile Metrics Dashboard</title>
    <script src="https://cdn.jsdelivr.net/npm/chart.js@4.4.0/dist/chart.umd.min.js"></script>
    <style>
        * {
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            background: #f5f5f5;
            color: #333;
            padding: 20px;
        }
        .container {
            max-width: 1400px;
            margin: 0 auto;
        }
        header {
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            color: white;
            padding: 30px;
            border-radius: 10px;
            margin-bottom: 30px;
            box-shadow: 0 4px 6px rgba(0,0,0,0.1);
        }
        header h1 {
            font-size: 2.5em;
            margin-bottom: 10px;
        }
        header p {
            opacity: 0.9;
            font-size: 1.1em;
        }
        .grid {
            display: grid;
            grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
            gap: 20px;
            margin-bottom: 30px;
        }
        .card {
            background: white;
            border-radius: 10px;
            padding: 25px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            transition: transform 0.2s, box-shadow 0.2s;
        }
        .card:hover {
            transform: translateY(-2px);
            box-shadow: 0 4px 8px rgba(0,0,0,0.15);
        }
        .card h2 {
            color: #667eea;
            margin-bottom: 15px;
            font-size: 1.5em;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        .metric {
            display: flex;
            justify-content: space-between;
            padding: 10px 0;
            border-bottom: 1px solid #eee;
        }
        .metric:last-child {
            border-bottom: none;
        }
        .metric-label {
            font-weight: 500;
            color: #666;
        }
        .metric-value {
            font-weight: 700;
            color: #333;
            font-size: 1.1em;
        }
        .chart-container {
            background: white;
            border-radius: 10px;
            padding: 25px;
            margin-bottom: 30px;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
        }
        .chart-container h2 {
            color: #667eea;
            margin-bottom: 20px;
            font-size: 1.5em;
            border-bottom: 2px solid #667eea;
            padding-bottom: 10px;
        }
        .chart-wrapper {
            position: relative;
            height: 400px;
            margin-bottom: 20px;
        }
        .status-badge {
            display: inline-block;
            padding: 5px 12px;
            border-radius: 20px;
            font-size: 0.85em;
            font-weight: 600;
        }
        .status-good {
            background: #d4edda;
            color: #155724;
        }
        .status-warning {
            background: #fff3cd;
            color: #856404;
        }
        .status-error {
            background: #f8d7da;
            color: #721c24;
        }
        .timestamp {
            color: #999;
            font-size: 0.9em;
            margin-top: 10px;
        }
    </style>
</head>
<body>
    <div class="container">
        <header>
            <h1>📊 PowerShell Profile Metrics Dashboard</h1>
            <p>Comprehensive code quality and performance insights</p>
            <div class="timestamp">Generated: $(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')</div>
        </header>

        <div class="grid">
            <div class="card">
                <h2>📁 Code Metrics</h2>
                <div id="code-metrics-content">
                    <div class="metric">
                        <span class="metric-label">Total Files</span>
                        <span class="metric-value" id="total-files">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Total Lines</span>
                        <span class="metric-value" id="total-lines">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Total Functions</span>
                        <span class="metric-value" id="total-functions">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Total Complexity</span>
                        <span class="metric-value" id="total-complexity">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Duplicate Functions</span>
                        <span class="metric-value" id="duplicate-functions">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Avg Lines/File</span>
                        <span class="metric-value" id="avg-lines">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Avg Functions/File</span>
                        <span class="metric-value" id="avg-functions">-</span>
                    </div>
                </div>
            </div>

            <div class="card">
                <h2>⚡ Performance Metrics</h2>
                <div id="performance-metrics-content">
                    <div class="metric">
                        <span class="metric-label">Full Startup (Mean)</span>
                        <span class="metric-value" id="startup-mean">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Fragments Loaded</span>
                        <span class="metric-value" id="fragments-count">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Slowest Fragment</span>
                        <span class="metric-value" id="slowest-fragment">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Fastest Fragment</span>
                        <span class="metric-value" id="fastest-fragment">-</span>
                    </div>
                </div>
            </div>

            <div class="card">
                <h2>📈 Quality Indicators</h2>
                <div id="quality-indicators-content">
                    <div class="metric">
                        <span class="metric-label">Code Quality Score</span>
                        <span class="metric-value" id="code-quality-score">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Complexity Ratio</span>
                        <span class="metric-value" id="complexity-ratio">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Function Density</span>
                        <span class="metric-value" id="function-density">-</span>
                    </div>
                </div>
            </div>

            <div class="card">
                <h2>🧪 Test Coverage</h2>
                <div id="test-coverage-content">
                    <div class="metric">
                        <span class="metric-label">Coverage</span>
                        <span class="metric-value" id="coverage-percent">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Covered Lines</span>
                        <span class="metric-value" id="covered-lines">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Total Lines</span>
                        <span class="metric-value" id="total-lines-coverage">-</span>
                    </div>
                    <div class="metric">
                        <span class="metric-label">Coverage Trend</span>
                        <span class="metric-value" id="coverage-trend">-</span>
                    </div>
                </div>
            </div>
        </div>

        <div class="chart-container">
            <h2>📊 Code Metrics Overview</h2>
            <div class="chart-wrapper">
                <canvas id="codeMetricsChart"></canvas>
            </div>
        </div>

        <div class="chart-container">
            <h2>⚡ Fragment Performance</h2>
            <div class="chart-wrapper">
                <canvas id="fragmentPerformanceChart"></canvas>
            </div>
        </div>

        $(if ($IncludeHistorical -and $historicalData) {
            @"
        <div class="chart-container">
            <h2>📈 Historical Trends</h2>
            <div class="chart-wrapper">
                <canvas id="historicalTrendsChart"></canvas>
            </div>
        </div>
"@
        })

        $(if ($coverageTrends) {
            @"
        <div class="chart-container">
            <h2>📊 Test Coverage Trends</h2>
            <div class="chart-wrapper">
                <canvas id="coverageTrendsChart"></canvas>
            </div>
        </div>
"@
        })

        $(if ($codeMetrics -and $codeMetrics.CodeSimilarity -and $codeMetrics.CodeSimilarity.Count -gt 0) {
            @"
        <div class="chart-container">
            <h2>🔍 Code Similarity Detection</h2>
            <div id="code-similarity-content">
                <p>Found $($codeMetrics.CodeSimilarity.Count) similar code blocks (similarity ≥ 70%)</p>
                <table style="width: 100%; border-collapse: collapse; margin-top: 20px;">
                    <thead>
                        <tr style="background: #f0f0f0;">
                            <th style="padding: 10px; text-align: left; border-bottom: 2px solid #ddd;">File 1</th>
                            <th style="padding: 10px; text-align: left; border-bottom: 2px solid #ddd;">File 2</th>
                            <th style="padding: 10px; text-align: center; border-bottom: 2px solid #ddd;">Similarity</th>
                            <th style="padding: 10px; text-align: left; border-bottom: 2px solid #ddd;">Block Type</th>
                        </tr>
                    </thead>
                    <tbody id="similarity-table-body">
                    </tbody>
                </table>
            </div>
        </div>
"@
        })
    </div>

    <script>
        // Code metrics data
        const codeMetrics = $($codeMetrics | ConvertTo-Json -Compress -Depth 10);
        const performanceMetrics = $($performanceMetrics | ConvertTo-Json -Compress -Depth 10);
        const historicalData = $($historicalData | ConvertTo-Json -Compress -Depth 10);
        const coverageTrends = $($coverageTrends | ConvertTo-Json -Compress -Depth 10);

        // Populate code metrics
        if (codeMetrics) {
            document.getElementById('total-files').textContent = codeMetrics.TotalFiles || '-';
            document.getElementById('total-lines').textContent = codeMetrics.TotalLines ? codeMetrics.TotalLines.toLocaleString() : '-';
            document.getElementById('total-functions').textContent = codeMetrics.TotalFunctions || '-';
            document.getElementById('total-complexity').textContent = codeMetrics.TotalComplexity || '-';
            document.getElementById('duplicate-functions').textContent = codeMetrics.DuplicateFunctions || 0;
            document.getElementById('avg-lines').textContent = codeMetrics.AverageLinesPerFile ? codeMetrics.AverageLinesPerFile.toFixed(2) : '-';
            document.getElementById('avg-functions').textContent = codeMetrics.AverageFunctionsPerFile ? codeMetrics.AverageFunctionsPerFile.toFixed(2) : '-';
            
            // Calculate quality indicators
            const complexityRatio = codeMetrics.TotalLines > 0 ? (codeMetrics.TotalComplexity / codeMetrics.TotalLines * 100).toFixed(2) : 0;
            const functionDensity = codeMetrics.TotalLines > 0 ? (codeMetrics.TotalFunctions / codeMetrics.TotalLines * 1000).toFixed(2) : 0;
            
            document.getElementById('complexity-ratio').textContent = complexityRatio + '%';
            document.getElementById('function-density').textContent = functionDensity + ' per 1K lines';
            
            // Code quality score
            if (codeMetrics.QualityScore) {
                const score = codeMetrics.QualityScore.Score;
                let scoreClass = 'status-good';
                if (score < 60) {
                    scoreClass = 'status-error';
                } else if (score < 80) {
                    scoreClass = 'status-warning';
                }
                document.getElementById('code-quality-score').innerHTML = '<span class="status-badge ' + scoreClass + '">' + score.toFixed(1) + '/100</span>';
            } else {
                // Fallback to old logic
                let qualityStatus = 'Good';
                let qualityClass = 'status-good';
                if (codeMetrics.DuplicateFunctions > 5) {
                    qualityStatus = 'Warning';
                    qualityClass = 'status-warning';
                }
                if (codeMetrics.DuplicateFunctions > 10) {
                    qualityStatus = 'Needs Attention';
                    qualityClass = 'status-error';
                }
                document.getElementById('code-quality-score').innerHTML = '<span class="status-badge ' + qualityClass + '">' + qualityStatus + '</span>';
            }
        }

        // Populate test coverage
        if (codeMetrics && codeMetrics.TestCoverage) {
            const coverage = codeMetrics.TestCoverage;
            document.getElementById('coverage-percent').textContent = coverage.CoveragePercent ? coverage.CoveragePercent.toFixed(2) + '%' : '-';
            document.getElementById('covered-lines').textContent = coverage.CoveredLines ? coverage.CoveredLines.toLocaleString() : '-';
            document.getElementById('total-lines-coverage').textContent = coverage.TotalLines ? coverage.TotalLines.toLocaleString() : '-';
            
            // Coverage trend
            if (coverageTrends && coverageTrends.CoverageChange !== undefined) {
                const change = coverageTrends.CoverageChange;
                let trendText = change.toFixed(2) + '%';
                let trendClass = '';
                if (change > 0) {
                    trendText = '+' + trendText;
                    trendClass = 'status-good';
                } else if (change < 0) {
                    trendClass = 'status-error';
                } else {
                    trendClass = 'status-warning';
                }
                document.getElementById('coverage-trend').innerHTML = '<span class="status-badge ' + trendClass + '">' + trendText + '</span>';
            } else {
                document.getElementById('coverage-trend').textContent = 'No trend data';
            }
        }

        // Populate code similarity table
        if (codeMetrics && codeMetrics.CodeSimilarity && codeMetrics.CodeSimilarity.length > 0) {
            const tbody = document.getElementById('similarity-table-body');
            codeMetrics.CodeSimilarity.slice(0, 20).forEach(sim => {
                const row = document.createElement('tr');
                row.style.borderBottom = '1px solid #eee';
                row.innerHTML = `
                    <td style="padding: 8px;">${sim.File1}</td>
                    <td style="padding: 8px;">${sim.File2}</td>
                    <td style="padding: 8px; text-align: center;">
                        <span class="status-badge ${sim.SimilarityPercent >= 90 ? 'status-error' : sim.SimilarityPercent >= 80 ? 'status-warning' : 'status-good'}">
                            ${sim.SimilarityPercent}%
                        </span>
                    </td>
                    <td style="padding: 8px;">${sim.Block1Type}</td>
                `;
                tbody.appendChild(row);
            });
        }

        // Populate performance metrics
        if (performanceMetrics) {
            document.getElementById('startup-mean').textContent = performanceMetrics.FullStartupMean ? performanceMetrics.FullStartupMean.toFixed(2) + ' ms' : '-';
            document.getElementById('fragments-count').textContent = performanceMetrics.Fragments ? performanceMetrics.Fragments.length : '-';
            
            if (performanceMetrics.Fragments && performanceMetrics.Fragments.length > 0) {
                const sorted = [...performanceMetrics.Fragments].sort((a, b) => b.MeanMs - a.MeanMs);
                document.getElementById('slowest-fragment').textContent = sorted[0].Fragment + ' (' + sorted[0].MeanMs.toFixed(2) + ' ms)';
                document.getElementById('fastest-fragment').textContent = sorted[sorted.length - 1].Fragment + ' (' + sorted[sorted.length - 1].MeanMs.toFixed(2) + ' ms)';
            }
        }

        // Code metrics chart
        if (codeMetrics) {
            const ctx1 = document.getElementById('codeMetricsChart').getContext('2d');
            new Chart(ctx1, {
                type: 'bar',
                data: {
                    labels: ['Files', 'Lines', 'Functions', 'Complexity'],
                    datasets: [{
                        label: 'Code Metrics',
                        data: [
                            codeMetrics.TotalFiles || 0,
                            (codeMetrics.TotalLines || 0) / 100,
                            codeMetrics.TotalFunctions || 0,
                            (codeMetrics.TotalComplexity || 0) / 10
                        ],
                        backgroundColor: [
                            'rgba(102, 126, 234, 0.8)',
                            'rgba(118, 75, 162, 0.8)',
                            'rgba(255, 99, 132, 0.8)',
                            'rgba(54, 162, 235, 0.8)'
                        ],
                        borderColor: [
                            'rgba(102, 126, 234, 1)',
                            'rgba(118, 75, 162, 1)',
                            'rgba(255, 99, 132, 1)',
                            'rgba(54, 162, 235, 1)'
                        ],
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        },
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    const labels = ['Files', 'Lines (×100)', 'Functions', 'Complexity (×10)'];
                                    return labels[context.dataIndex] + ': ' + context.parsed.y;
                                }
                            }
                        }
                    }
                }
            });
        }

        // Fragment performance chart
        if (performanceMetrics && performanceMetrics.Fragments) {
            const topFragments = [...performanceMetrics.Fragments]
                .sort((a, b) => b.MeanMs - a.MeanMs)
                .slice(0, 15);
            
            const ctx2 = document.getElementById('fragmentPerformanceChart').getContext('2d');
            new Chart(ctx2, {
                type: 'bar',
                data: {
                    labels: topFragments.map(f => f.Fragment),
                    datasets: [{
                        label: 'Mean Load Time (ms)',
                        data: topFragments.map(f => f.MeanMs),
                        backgroundColor: 'rgba(102, 126, 234, 0.8)',
                        borderColor: 'rgba(102, 126, 234, 1)',
                        borderWidth: 1
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    indexAxis: 'y',
                    scales: {
                        x: {
                            beginAtZero: true
                        }
                    },
                    plugins: {
                        legend: {
                            display: false
                        }
                    }
                }
            });
        }

        // Coverage trends chart
        $(if ($coverageTrends) {
            @"
        if (coverageTrends && coverageTrends.HistoricalData && coverageTrends.HistoricalData.length > 0) {
            const ctx4 = document.getElementById('coverageTrendsChart').getContext('2d');
            const coverageLabels = coverageTrends.HistoricalData.map(d => {
                const date = new Date(d.Date || d.Timestamp);
                return date.toLocaleDateString();
            });
            
            new Chart(ctx4, {
                type: 'line',
                data: {
                    labels: coverageLabels,
                    datasets: [{
                        label: 'Coverage %',
                        data: coverageTrends.HistoricalData.map(d => d.CoveragePercent || 0),
                        borderColor: 'rgba(102, 126, 234, 1)',
                        backgroundColor: 'rgba(102, 126, 234, 0.2)',
                        tension: 0.4,
                        fill: true
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: false,
                            min: 0,
                            max: 100,
                            ticks: {
                                callback: function(value) {
                                    return value + '%';
                                }
                            }
                        }
                    },
                    plugins: {
                        legend: {
                            display: true,
                            position: 'top'
                        },
                        tooltip: {
                            callbacks: {
                                label: function(context) {
                                    return 'Coverage: ' + context.parsed.y.toFixed(2) + '%';
                                }
                            }
                        }
                    }
                }
            });
        }
"@
        })

        // Historical trends chart
        $(if ($IncludeHistorical -and $historicalData) {
            @"
        if (historicalData && historicalData.length > 0) {
            const ctx3 = document.getElementById('historicalTrendsChart').getContext('2d');
            const labels = historicalData.map(d => {
                const date = new Date(d.Timestamp || d.Timestamp);
                return date.toLocaleDateString();
            });
            
            new Chart(ctx3, {
                type: 'line',
                data: {
                    labels: labels,
                    datasets: [{
                        label: 'Total Files',
                        data: historicalData.map(d => d.CodeMetrics?.TotalFiles || 0),
                        borderColor: 'rgba(102, 126, 234, 1)',
                        backgroundColor: 'rgba(102, 126, 234, 0.2)',
                        tension: 0.4
                    }, {
                        label: 'Total Lines',
                        data: historicalData.map(d => (d.CodeMetrics?.TotalLines || 0) / 100),
                        borderColor: 'rgba(118, 75, 162, 1)',
                        backgroundColor: 'rgba(118, 75, 162, 0.2)',
                        tension: 0.4
                    }, {
                        label: 'Total Functions',
                        data: historicalData.map(d => d.CodeMetrics?.TotalFunctions || 0),
                        borderColor: 'rgba(255, 99, 132, 1)',
                        backgroundColor: 'rgba(255, 99, 132, 0.2)',
                        tension: 0.4
                    }]
                },
                options: {
                    responsive: true,
                    maintainAspectRatio: false,
                    scales: {
                        y: {
                            beginAtZero: true
                        }
                    },
                    plugins: {
                        legend: {
                            position: 'top'
                        }
                    }
                }
            });
        }
"@
        })
    </script>
</body>
</html>
"@

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


