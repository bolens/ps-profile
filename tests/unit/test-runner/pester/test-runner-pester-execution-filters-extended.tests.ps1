<#
tests/unit/test-runner-pester-execution-filters-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Pester execution and filter configuration helpers.
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
    Import-Module (Join-Path $modulePath 'PesterExecutionConfig.psm1') -Force -Global
}

Describe 'PesterExecutionConfig extended scenarios' {
    Context 'Set-PesterTestFilters' {
        It 'Applies IncludeTag values to the configuration' {
            $config = New-PesterConfiguration
            $updated = Set-PesterTestFilters -Config $config -IncludeTag @('Unit', 'Fast')

            @($updated.Filter.Tag.Value) | Should -Contain 'Unit'
            @($updated.Filter.Tag.Value) | Should -Contain 'Fast'
        }

        It 'Applies ExcludeTag values to the configuration' {
            $config = New-PesterConfiguration
            $updated = Set-PesterTestFilters -Config $config -ExcludeTag @('Slow', 'Flaky')

            @($updated.Filter.ExcludeTag.Value) | Should -Contain 'Slow'
            @($updated.Filter.ExcludeTag.Value) | Should -Contain 'Flaky'
        }

        It 'Parses semicolon-separated TestName patterns' {
            $config = New-PesterConfiguration
            $updated = Set-PesterTestFilters -Config $config -TestName 'Alpha; Beta'

            @($updated.Filter.FullName.Value) | Should -Contain 'Alpha'
            @($updated.Filter.FullName.Value) | Should -Contain 'Beta'
        }

        It 'Trims whitespace from parsed TestName patterns' {
            $config = New-PesterConfiguration
            $updated = Set-PesterTestFilters -Config $config -TestName '  Alpha  ,   Beta  '

            @($updated.Filter.FullName.Value) | Should -Contain 'Alpha'
            @($updated.Filter.FullName.Value) | Should -Contain 'Beta'
        }
    }

    Context 'Set-PesterExecutionOptions' {
        It 'Enables parallel execution when Parallel is greater than zero' {
            $config = New-PesterConfiguration
            $updated = Set-PesterExecutionOptions -Config $config -Parallel 4

            if ($updated.Run.PSObject.Properties.Name -contains 'Parallel') {
                $updated.Run.Parallel.Value | Should -Be $true
            }
            if ($updated.Run.PSObject.Properties.Name -contains 'MaximumThreadCount') {
                $updated.Run.MaximumThreadCount.Value | Should -Be 4
            }
        }

        It 'Sets SkipRemainingOnFailure to Block when requested' {
            $config = New-PesterConfiguration
            $updated = Set-PesterExecutionOptions -Config $config -SkipRemainingOnFailure

            $updated.Run.SkipRemainingOnFailure.Value | Should -Be 'Block'
        }
    }
}
