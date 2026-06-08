<#
tests/unit/utility-collect-code-metrics.tests.ps1

.SYNOPSIS
    Behavioral unit tests for collect-code-metrics.ps1 on a narrow fixture path.
#>

function global:New-CodeMetricsFixtureDirectory {
    $fixtureDir = New-TestTempDirectory -Prefix 'CodeMetricsFixture'
    Set-Content -LiteralPath (Join-Path $fixtureDir 'sample.ps1') -Value @'
function Get-CodeMetricsFixtureSample {
    42
}
'@ -Encoding UTF8
    return $fixtureDir
}

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
    $script:CollectMetricsScript = Join-Path $script:TestRepoRoot 'scripts' 'utils' 'metrics' 'collect-code-metrics.ps1'
    $ConfirmPreference = 'None'
}

Describe 'collect-code-metrics.ps1 execution' {
    It 'Collects metrics for a narrow fixture path and writes JSON output' {
        $fixtureDir = New-CodeMetricsFixtureDirectory
        $outputFile = Join-Path $fixtureDir 'metrics.json'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:CollectMetricsScript -ArgumentList @(
                '-Path', $fixtureDir,
                '-OutputPath', $outputFile
            )

            $result.ExitCode | Should -Be 0
            Test-Path -LiteralPath $outputFile | Should -BeTrue
            $json = Get-Content -LiteralPath $outputFile -Raw | ConvertFrom-Json
            $json.Timestamp | Should -Not -BeNullOrEmpty
        }
        finally {
            if (Test-Path -LiteralPath $fixtureDir) {
                Remove-Item -LiteralPath $fixtureDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Includes test coverage metrics when a coverage XML path is provided' {
        $fixtureDir = New-CodeMetricsFixtureDirectory
        $coverageXml = Join-Path $fixtureDir 'coverage.xml'
        $outputFile = Join-Path $fixtureDir 'metrics-with-coverage.json'
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

        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:CollectMetricsScript -ArgumentList @(
                '-Path', $fixtureDir,
                '-OutputPath', $outputFile,
                '-CoverageXmlPath', $coverageXml
            )

            $result.ExitCode | Should -Be 0
            Test-Path -LiteralPath $outputFile | Should -BeTrue
            $result.Output | Should -Match 'Collecting test coverage|Coverage:'
            $json = Get-Content -LiteralPath $outputFile -Raw | ConvertFrom-Json
            $json.PSObject.Properties.Name | Should -Contain 'TestCoverage'
            $json.TestCoverage.CoveragePercent | Should -BeGreaterOrEqual 0
        }
        finally {
            if (Test-Path -LiteralPath $fixtureDir) {
                Remove-Item -LiteralPath $fixtureDir -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }

    It 'Warns and continues when a requested analysis path does not exist' {
        $missingPath = Join-Path (New-TestTempDirectory -Prefix 'CodeMetricsMissingPath') 'does-not-exist'
        $outputFile = Join-Path (Split-Path -Parent $missingPath) 'metrics-missing-path.json'
        try {
            $result = Invoke-TestScriptFile -ScriptPath $script:CollectMetricsScript -ArgumentList @(
                '-Path', $missingPath,
                '-OutputPath', $outputFile
            )

            $result.ExitCode | Should -Be 0
            $result.Output | Should -Match 'Failed to collect metrics|Warning'
        }
        finally {
            $parent = Split-Path -Parent $missingPath
            if (Test-Path -LiteralPath $parent) {
                Remove-Item -LiteralPath $parent -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
    }
}
