<#
tests/unit/profile-batch-loading-summary-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for BatchLoadingSummary tracking helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'BatchLoadingSummary.ps1')
}

AfterAll {
    Remove-Variable -Name BatchLoadingInfo -Scope Global -ErrorAction SilentlyContinue
}

Describe 'BatchLoadingSummary extended scenarios' {
    BeforeEach {
        Initialize-BatchLoadingInfo
    }

    Context 'Initialize-BatchLoadingInfo' {
        It 'Resets existing batch data when called again' {
            Record-BatchLoading -BatchNumber 1 -TotalBatches 2 -FragmentCount 3 -FragmentNames @('a', 'b', 'c')
            Set-TotalFragmentCount -Count 99

            Initialize-BatchLoadingInfo

            $global:BatchLoadingInfo.Batches.Count | Should -Be 0
            $global:BatchLoadingInfo.TotalFragments | Should -Be 0
        }
    }

    Context 'Record-DependencyParsing' {
        It 'Stores parsing duration and dependency level count' {
            Record-DependencyParsing -ParsingTime 125 -DependencyLevels 4

            $global:BatchLoadingInfo.DependencyParsingTime | Should -Be 125
            $global:BatchLoadingInfo.DependencyLevels | Should -Be 4
        }
    }

    Context 'Record-BatchLoading' {
        It 'Calculates progress percentage for each batch entry' {
            Record-BatchLoading -BatchNumber 3 -TotalBatches 4 -FragmentCount 2 -FragmentNames @('git', 'env')

            $global:BatchLoadingInfo.Batches[0].ProgressPercent | Should -Be 75
            $global:BatchLoadingInfo.Batches[0].FragmentNames | Should -Contain 'git'
        }
    }

    Context 'Record-FragmentResults' {
        It 'Avoids duplicate succeeded fragment names' {
            Record-FragmentResults -SucceededFragments @('bootstrap', 'bootstrap', 'git') -FailedFragments @()

            $global:BatchLoadingInfo.SucceededFragments.Count | Should -Be 2
            @($global:BatchLoadingInfo.SucceededFragments) | Should -Contain 'bootstrap'
            @($global:BatchLoadingInfo.SucceededFragments) | Should -Contain 'git'
        }

        It 'Records failed fragments with error messages' {
            Record-FragmentResults -SucceededFragments @() -FailedFragments @(
                @{ Name = 'broken-fragment'; Error = 'syntax error' }
            )

            $global:BatchLoadingInfo.FailedFragments.Count | Should -Be 1
            $global:BatchLoadingInfo.FailedFragments[0].Name | Should -Be 'broken-fragment'
            $global:BatchLoadingInfo.FailedFragments[0].Error | Should -Be 'syntax error'
        }
    }

    Context 'Show-BatchLoadingSummary' {
        It 'Returns without output when no batches were recorded' {
            { Show-BatchLoadingSummary } | Should -Not -Throw
        }
    }
}
