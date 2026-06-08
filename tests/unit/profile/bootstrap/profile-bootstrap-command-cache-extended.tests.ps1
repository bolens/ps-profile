<#
tests/unit/profile-bootstrap-command-cache-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/bootstrap/CommandCache.ps1'
}
Describe 'profile.d/bootstrap/CommandCache.ps1 extended scenarios' {
    It 'Documents command availability caching utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Command availability caching utilities'
        $c | Should -Match 'preferred function for command detection'
    }
    It 'Defines Test-CachedCommand with CacheTTLMinutes parameter' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-CachedCommand'
        $c | Should -Match 'CacheTTLMinutes'
        $c | Should -Match 'Get-CachedExternalCommand'
    }
    It 'Provides cache management helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Clear-TestCachedCommandCache'
        $c | Should -Match 'Remove-TestCachedCommandCacheEntry'
    }
}
