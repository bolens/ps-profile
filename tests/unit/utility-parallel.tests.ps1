#
# Parallel execution helper tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    Import-TestCommonModule | Out-Null
}

Describe 'Invoke-Parallel' {
    Context 'General behavior' {
        It 'Returns empty results for empty input collections' {
            $result = Invoke-Parallel -Items @() -ScriptBlock { $_ }
            $result | Should -BeNullOrEmpty
        }

        It 'Processes items and returns results' {
            $result = Invoke-Parallel -Items @(1) -ScriptBlock { $_ * 2 }
            $result.Count | Should -Be 1
            $result[0] | Should -Be 2
        }
    }
}
