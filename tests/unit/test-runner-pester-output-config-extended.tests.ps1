<#
tests/unit/test-runner-pester-output-config-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for PesterOutputConfig priority and CI settings.
#>

BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1

    $modulePath = Join-Path $PSScriptRoot '../../scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'PesterOutputConfig.psm1') -Force -Global

    $script:TempDir = New-TestTempDirectory -Prefix 'PesterOutputConfigExtended'
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
}

AfterAll {
    if ($script:TempDir -and (Test-Path -LiteralPath $script:TempDir)) {
        Remove-Item -LiteralPath $script:TempDir -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'PesterOutputConfig extended scenarios' {
    Context 'Set-PesterOutputVerbosity' {
        It 'Prefers Quiet over CI and explicit output format' {
            $config = New-PesterConfiguration
            $updated = Set-PesterOutputVerbosity -Config $config -CI -OutputFormat 'Detailed' -Quiet

            $updated.Output.Verbosity.Value | Should -Be 'None'
        }

        It 'Prefers Verbose over CI mode' {
            $config = New-PesterConfiguration
            $updated = Set-PesterOutputVerbosity -Config $config -CI -Verbose

            $updated.Output.Verbosity.Value | Should -Be 'Detailed'
        }

        It 'Maps Minimal output format to None verbosity' {
            $config = New-PesterConfiguration
            $updated = Set-PesterOutputVerbosity -Config $config -OutputFormat 'Minimal'

            $updated.Output.Verbosity.Value | Should -Be 'None'
        }
    }

    Context 'Set-PesterCIOptimizations' {
        It 'Defaults test result output under the repository root' {
            $config = New-PesterConfiguration
            $updated = Set-PesterCIOptimizations -Config $config -RepoRoot $script:RepoRoot

            $updated.TestResult.Enabled.Value | Should -Be $true
            ($updated.TestResult.OutputPath.Value -replace '\\', '/') | Should -Match 'test-results\.xml$'
            $updated.TestResult.OutputFormat.Value | Should -Be 'NUnitXml'
        }

        It 'Enables Cobertura coverage output when Coverage is specified' {
            $config = New-PesterConfiguration
            $updated = Set-PesterCIOptimizations -Config $config -Coverage -RepoRoot $script:RepoRoot

            $updated.CodeCoverage.OutputFormat.Value | Should -Be 'Cobertura'
        }
    }

    Context 'Set-PesterTestResults' {
        It 'Selects NUnit output for .nunit extensions' {
            $config = New-PesterConfiguration
            $outputPath = Join-Path $script:TempDir 'results.nunit'
            $updated = Set-PesterTestResults -Config $config -OutputPath $outputPath

            $updated.TestResult.OutputFormat.Value | Should -Be 'NUnitXml'
        }
    }
}
