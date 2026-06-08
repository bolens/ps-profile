<#
tests/unit/profile-bootstrap-module-path-cache-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/ModulePathCache.ps1'
}
Describe 'profile.d/bootstrap/ModulePathCache.ps1 extended scenarios' {
    It 'Documents module path existence caching utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Module path existence caching utilities'
        $c | Should -Match 'PSProfileModulePathCache'
    }
    It 'Defines Test-ModulePath with concurrent cache dictionary' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-ModulePath'
        $c | Should -Match 'ConcurrentDictionary'
        $c | Should -Match 'avoid repeated Test-Path'
    }
    It 'Defines Clear-ModulePathCache and Remove-ModulePathCacheEntry' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Clear-ModulePathCache'
        $c | Should -Match 'Remove-ModulePathCacheEntry'
    }
}
