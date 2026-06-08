<#
tests/unit/profile-batch-loading-display-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for batch loading summary display helpers.
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
    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'BatchLoadingSummary.ps1')
}

AfterAll {
    Remove-Variable -Name BatchLoadingInfo -Scope Global -ErrorAction SilentlyContinue
}

Describe 'BatchLoadingSummary display extended scenarios' {
    BeforeEach {
        Initialize-BatchLoadingInfo
    }

    Context '_ConvertToNameTableRows' {
        It 'Returns an empty array for blank names' {
            _ConvertToNameTableRows -Names @('   ') | Should -Be @()
        }

        It 'Builds multi-column rows with FragmentA through FragmentD keys' {
            $rows = _ConvertToNameTableRows -Names @('git', 'env', 'files', 'utils', 'cloud')

            $rowCount = $rows.Count
            $rowCount | Should -BeGreaterThan (1)
            $rows[0].PSObject.Properties.Name | Should -Contain 'FragmentA'
            $rows[0].FragmentA | Should -Be 'git'
        }

        It 'Limits columns to the number of supplied names' {
            $rows = _ConvertToNameTableRows -Names @('only-one') -Columns 4

            $rows.Count | Should -Be 1
            $rows[0].PSObject.Properties.Name | Should -Contain 'FragmentA'
            $rows[0].PSObject.Properties.Name | Should -Not -Contain 'FragmentB'
        }
    }

    Context 'Show-BatchLoadingSummary' {
        It 'Renders batch progress when loading data exists' {
            Record-BatchLoading -BatchNumber 1 -TotalBatches 2 -FragmentCount 2 -FragmentNames @('git', 'env')
            Record-FragmentResults -SucceededFragments @('git') -FailedFragments @(
                @{ Name = 'broken'; Error = 'load failed' }
            )

            $output = @(Show-BatchLoadingSummary 6>&1 | ForEach-Object { "$_" })

            ($output -join ' ') | Should -Match 'Fragment Loading Summary'
            ($output -join ' ') | Should -Match 'broken'
        }

        It 'Includes dependency parsing details when recorded' {
            Record-DependencyParsing -ParsingTime 250 -DependencyLevels 3
            Record-BatchLoading -BatchNumber 1 -TotalBatches 1 -FragmentCount 1 -FragmentNames @('bootstrap')

            $output = @(Show-BatchLoadingSummary 6>&1 | ForEach-Object { "$_" }) -join ' '

            $output | Should -Match 'Dependency Analysis'
            $output | Should -Match '250'
        }

        It 'Uses TotalFragmentCount when result lists are empty' {
            Set-TotalFragmentCount -Count 12
            Record-BatchLoading -BatchNumber 1 -TotalBatches 1 -FragmentCount 1 -FragmentNames @('bootstrap')

            $output = @(Show-BatchLoadingSummary 6>&1 | ForEach-Object { "$_" }) -join ' '

            $output | Should -Match '12'
        }
    }
}
