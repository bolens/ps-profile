#
# Parallel execution helper tests.
#

. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    # Import the Parallel module (Common.psm1 no longer exists)
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'Parallel.psm1') -DisableNameChecking -ErrorAction Stop -Global
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
