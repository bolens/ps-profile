<#
tests/unit/utility-track-coverage-trends.tests.ps1

.SYNOPSIS
    Behavioral unit tests for track-coverage-trends.ps1 when coverage data is absent.
#>

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TrackCoverageScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'metrics' 'track-coverage-trends.ps1'
    $ConfirmPreference = 'None'
}

Describe 'track-coverage-trends.ps1 execution' {
    It 'Exits successfully when no coverage XML file is available' {
        $historyDir = New-TestTempDirectory -Prefix 'CoverageTrendHistory'
            $missingCoverage = Join-Path $historyDir 'missing-coverage.xml'
            $result = Invoke-TestScriptFile -ScriptPath $script:TrackCoverageScript -ArgumentList @(
                '-CoverageXmlPath', $missingCoverage,
                '-HistoryPath', $historyDir,
                '-Days', '1'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Coverage file not found|coverage'
    }

    It 'Saves a coverage snapshot when a minimal coverage XML file is provided' {
        $fixtureDir = New-TestTempDirectory -Prefix 'CoverageTrendSnapshot'
        $coverageXml = Join-Path $fixtureDir 'coverage.xml'
        $historyDir = Join-Path $fixtureDir 'history'
        @'
<?xml version="1.0" encoding="utf-8"?>
<Coverage>
    <Module ModulePath="C:\test\Sample.psm1">
        <Function FunctionName="Test-Sample">
            <Line Number="1" Covered="true" />
            <Line Number="2" Covered="false" />
        </Function>
    </Module>
</Coverage>
'@ | Set-Content -LiteralPath $coverageXml -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:TrackCoverageScript -ArgumentList @(
                '-CoverageXmlPath', $coverageXml,
                '-HistoryPath', $historyDir,
                '-SaveSnapshot',
                '-Days', '1'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Current Coverage|Coverage snapshot saved'
            @(Get-ChildItem -LiteralPath $historyDir -Filter 'coverage-*.json' -ErrorAction SilentlyContinue).Count |
                Should -BeGreaterThan 0
    }

    It 'Reports when no historical coverage snapshots exist in the history directory' {
        $historyDir = New-TestTempDirectory -Prefix 'CoverageTrendEmptyHistory'
        $coverageXml = Join-Path (New-TestTempDirectory -Prefix 'CoverageTrendCurrent') 'coverage.xml'
        @'
<?xml version="1.0" encoding="utf-8"?>
<Coverage>
    <Module ModulePath="C:\test\Sample.psm1">
        <Function FunctionName="Test-Sample">
            <Line Number="1" Covered="true" />
        </Function>
    </Module>
</Coverage>
'@ | Set-Content -LiteralPath $coverageXml -Encoding UTF8

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:TrackCoverageScript -ArgumentList @(
                '-CoverageXmlPath', $coverageXml,
                '-HistoryPath', $historyDir,
                '-Days', '30'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'No historical coverage data found|Coverage Trends'
        }
        finally {
            foreach ($path in @($historyDir, (Split-Path -Parent $coverageXml))) {
            }
        }
    }

    It 'Analyzes coverage trends when historical snapshots exist in the history directory' {
        $fixtureDir = New-TestTempDirectory -Prefix 'CoverageTrendHistoryData'
        $historyDir = Join-Path $fixtureDir 'history'
        $coverageXml = Join-Path $fixtureDir 'coverage.xml'
        New-Item -ItemType Directory -Path $historyDir -Force | Out-Null

        $olderSnapshot = @{
            Timestamp       = (Get-Date).AddDays(-2).ToUniversalTime().ToString('o')
            CoveragePercent = 50.0
            TotalLines      = 100
            CoveredLines    = 50
        }
        $newerSnapshot = @{
            Timestamp       = (Get-Date).AddDays(-1).ToUniversalTime().ToString('o')
            CoveragePercent = 75.0
            TotalLines      = 100
            CoveredLines    = 75
        }
        $olderSnapshot | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $historyDir 'coverage-20260101-120000.json') -Encoding UTF8
        $newerSnapshot | ConvertTo-Json | Set-Content -LiteralPath (Join-Path $historyDir 'coverage-20260102-120000.json') -Encoding UTF8

        @'
<?xml version="1.0" encoding="utf-8"?>
<Coverage>
    <Module ModulePath="C:\test\Sample.psm1">
        <Function FunctionName="Test-Sample">
            <Line Number="1" Covered="true" />
            <Line Number="2" Covered="true" />
            <Line Number="3" Covered="false" />
            <Line Number="4" Covered="false" />
        </Function>
    </Module>
</Coverage>
'@ | Set-Content -LiteralPath $coverageXml -Encoding UTF8

            $result = Invoke-TestScriptFile -ScriptPath $script:TrackCoverageScript -ArgumentList @(
                '-CoverageXmlPath', $coverageXml,
                '-HistoryPath', $historyDir,
                '-Days', '30'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Analyzing 2 historical snapshots|Coverage Trends|historical snapshots'
    }
}
