<#
tests/unit/library-fragment-loader-on-demand-extended.tests.ps1
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
    $script:ModulePath = Join-Path $script:TestRepoRoot 'scripts/lib/fragment/FragmentLoader.psm1'
}
Describe 'scripts/lib/fragment/FragmentLoader.psm1 extended scenarios' {
    It 'Documents on-demand profile fragment loading helpers' {
        $c = Get-Content -LiteralPath $script:ModulePath -Raw
        $c | Should -Match 'On-demand profile fragment loading helpers'
        $c | Should -Match 'profile.d fragments by name'
    }
    It 'Imports FragmentLoading and FragmentErrorHandling dependencies' {
        $c = Get-Content -LiteralPath $script:ModulePath -Raw
        $c | Should -Match 'FragmentIdempotency.psm1'
        $c | Should -Match 'FragmentLoading.psm1'
        $c | Should -Match 'FragmentErrorHandling.psm1'
    }
    It 'Defines Get-ProfileDirectory and Get-FragmentPath resolvers' {
        $c = Get-Content -LiteralPath $script:ModulePath -Raw
        $c | Should -Match 'Get-ProfileDirectory'
        $c | Should -Match 'Get-FragmentPath'
        $c | Should -Match 'ProfileFragmentRoot'
    }
}
