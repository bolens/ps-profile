<#
tests/unit/profile-files-module-registry-fallback-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/files-module-registry.ps1'
}
Describe 'profile.d/files-module-registry.ps1 registry fallback extended scenarios' {
    It 'Returns early when registry key is missing' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ContainsKey'
        $c | Should -Match 'No module registry entry'
        $c | Should -Match 'return'
    }
    It 'Tracks loaded and failed module counts' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'loadedCount'
        $c | Should -Match 'failedCount'
        $c | Should -Match 'Loaded .* modules for'
    }
    It 'Splits registry Dir paths into module path segments' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'pathSegments = .+Dir -split'
        $c | Should -Match 'modulePath = .+pathSegments'
        $c | Should -Match 'Import-FragmentModule'
    }
}
