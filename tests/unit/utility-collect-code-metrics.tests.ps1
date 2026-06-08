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
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

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
}
