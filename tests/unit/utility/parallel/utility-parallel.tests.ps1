#
# Parallel execution helper tests.
#

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
    # Import the Parallel module (Common.psm1 no longer exists)
    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $libPath 'parallel' 'Parallel.psm1') -DisableNameChecking -ErrorAction Stop -Global
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
