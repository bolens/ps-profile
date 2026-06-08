<#
tests/unit/utility-track-coverage-trends.tests.ps1

.SYNOPSIS
    Behavioral unit tests for track-coverage-trends.ps1 when coverage data is absent.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:TrackCoverageScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'metrics' 'track-coverage-trends.ps1'
    $ConfirmPreference = 'None'
}

Describe 'track-coverage-trends.ps1 execution' {
    It 'Exits successfully when no coverage XML file is available' {
        $historyDir = New-TestTempDirectory -Prefix 'CoverageTrendHistory'
        try {
            $missingCoverage = Join-Path $historyDir 'missing-coverage.xml'
            $result = Invoke-TestScriptFile -ScriptPath $script:TrackCoverageScript -ArgumentList @(
                '-CoverageXmlPath', $missingCoverage,
                '-HistoryPath', $historyDir,
                '-Days', '1'
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Coverage file not found|coverage'
        }
        finally {
            if (Test-Path -LiteralPath $historyDir) {
                Remove-Item -LiteralPath $historyDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
