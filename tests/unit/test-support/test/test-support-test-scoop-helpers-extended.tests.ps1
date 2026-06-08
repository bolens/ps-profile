<#
tests/unit/test-support-test-scoop-helpers-extended.tests.ps1
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'tests/TestSupport/TestScoopHelpers.ps1'
}
Describe 'tests/TestSupport/TestScoopHelpers.ps1 extended scenarios' {
    It 'Documents Scoop package availability testing utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestScoopHelpers.ps1'
        $c | Should -Match 'Scoop package availability'
    }
    It 'Defines Test-ScoopPackageAvailable helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-ScoopPackageAvailable'
    }
    It 'Integrates with scoop list for package detection' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-ScoopPackageAvailable'
        $c | Should -Match 'scoop list'
    }
}

