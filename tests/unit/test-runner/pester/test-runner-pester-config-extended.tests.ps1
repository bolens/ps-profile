<#
tests/unit/test-runner-pester-config-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Pester configuration filter and execution edge cases.
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
    $modulePath = Join-Path (Get-TestRepoRoot -StartPath $PSScriptRoot) 'scripts/utils/code-quality/modules'
    Import-Module (Join-Path $modulePath 'PesterConfig.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'PesterOutputConfig.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'PesterCoverageConfig.psm1') -Force -Global
    Import-Module (Join-Path $modulePath 'PesterExecutionConfig.psm1') -Force -Global

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
}

Describe 'PesterConfig extended scenarios' {
    Context 'New-PesterTestConfiguration' {
        It 'Applies coverage thresholds when Coverage is enabled' {
            $config = New-PesterTestConfiguration -Coverage -MinimumCoverage 90 -ProfileDir 'profile.d' -RepoRoot $script:RepoRoot

            $config.CodeCoverage.Enabled.Value | Should -Be $true
            $config.CodeCoverage.CoveragePercentTarget.Value | Should -Be 90
        }

        It 'Configures SkipRemainingOnFailure through the facade' {
            $config = New-PesterTestConfiguration -SkipRemainingOnFailure

            $config.Run.SkipRemainingOnFailure.Value | Should -Be 'Block'
        }
    }

    Context 'Set-PesterTestFilters' {
        It 'Ignores whitespace-only TestName values' {
            $config = New-PesterConfiguration
            $updated = Set-PesterTestFilters -Config $config -TestName '   '

            @($updated.Filter.FullName.Value).Count | Should -Be 0
        }

        It 'Parses mixed OR and comma separated patterns' {
            $config = New-PesterConfiguration
            $updated = Set-PesterTestFilters -Config $config -TestName 'Alpha OR Beta, Gamma'

            @($updated.Filter.FullName.Value) | Should -Contain 'Alpha'
            @($updated.Filter.FullName.Value) | Should -Contain 'Beta'
            @($updated.Filter.FullName.Value) | Should -Contain 'Gamma'
        }
    }

    Context 'Set-PesterExecutionOptions' {
        It 'Does not enable parallel execution when Parallel is zero' {
            $config = New-PesterConfiguration
            $updated = Set-PesterExecutionOptions -Config $config -Parallel 0

            if ($updated.Run.PSObject.Properties.Name -contains 'Parallel') {
                $updated.Run.Parallel.Value | Should -Be $false
            }
            else {
                Set-ItResult -Skipped -Because 'Pester Run.Parallel is not available in this Pester version'
            }
        }
    }
}
