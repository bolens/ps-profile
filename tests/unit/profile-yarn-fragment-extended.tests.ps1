<#
tests/unit/profile-yarn-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/yarn.ps1'
}
Describe 'profile.d/yarn.ps1 extended scenarios' {
    It 'Declares standard tier for web and development Yarn helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: web, development'
    }
    It 'Defines Invoke-Yarn guarded by Test-CachedCommand yarn' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-Yarn'
        $c | Should -Match 'Test-CachedCommand yarn'
    }
    It 'Documents PowerShell.Profile.Yarn module metadata' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PowerShell.Profile.Yarn'
        $c | Should -Match 'Add-YarnPackage'
    }
}
