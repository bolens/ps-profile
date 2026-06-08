<#
tests/unit/test-runner-pester-output-config.tests.ps1

.SYNOPSIS
    Unit tests for PesterOutputConfig format handling.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'PesterOutputConfig.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'PesterOutputConfigTests'
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PesterOutputConfig Module' {
    Context 'Set-PesterTestResults' {
        It 'Selects JSON output format based on file extension' {
            $config = New-PesterConfiguration
            $jsonPath = Join-Path $script:TempDir 'results.json'
            $updated = Set-PesterTestResults -Config $config -OutputPath $jsonPath

            $updated.TestResult.Enabled.Value | Should -Be $true
            $updated.TestResult.OutputPath.Value | Should -Be $jsonPath
            $updated.TestResult.OutputFormat.Value | Should -Be 'Json'
        }

        It 'Builds output path from TestResultPath directory' {
            $config = New-PesterConfiguration
            $resultDir = Join-Path $script:TempDir 'ci-output'
            New-Item -ItemType Directory -Path $resultDir -Force | Out-Null

            $updated = Set-PesterTestResults -Config $config -TestResultPath $resultDir

            $updated.TestResult.Enabled.Value | Should -Be $true
            ($updated.TestResult.OutputPath.Value -replace '\\', '/') | Should -Match 'ci-output/test-results\.xml'
            $updated.TestResult.OutputFormat.Value | Should -Be 'NUnitXml'
        }
    }

    Context 'Set-PesterOutputVerbosity' {
        It 'Honors CI verbosity when Quiet is not specified' {
            $config = New-PesterConfiguration
            $updated = Set-PesterOutputVerbosity -Config $config -CI

            $updated.Output.Verbosity.Value | Should -Be 'Normal'
        }

        It 'Uses explicit output format when no switches are set' {
            $config = New-PesterConfiguration
            $updated = Set-PesterOutputVerbosity -Config $config -OutputFormat 'Detailed'

            $updated.Output.Verbosity.Value | Should -Be 'Detailed'
        }
    }
}
