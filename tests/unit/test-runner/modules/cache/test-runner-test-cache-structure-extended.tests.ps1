<#
tests/unit/test-runner-test-cache-structure-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'scripts/utils/code-quality/modules/TestCache.psm1'
}
Describe 'scripts/utils/code-quality/modules/TestCache.psm1 structure extended scenarios' {
    It 'Documents test result caching utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test result caching utilities'
        $c | Should -Match 'TestCache.psm1'
    }
    It 'Defines cache status and save helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-TestCacheStatus'
        $c | Should -Match 'Save-TestCache'
        $c | Should -Match 'Export-ModuleMember'
    }
    It 'Supports SQLite cache with JSON fallback' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'TestCacheDatabase.psm1'
        $c | Should -Match 'UseSqliteCache'
        $c | Should -Match 'results.cache'
    }
}
