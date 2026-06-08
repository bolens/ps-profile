<#
tests/unit/profile-pnpm-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/pnpm.ps1'
}
Describe 'profile.d/pnpm.ps1 extended scenarios' {
    It 'Declares standard tier and aliases npm and yarn to pnpm when available' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match "Set-Alias -Name npm -Value pnpm"
    }
    It 'Defines Invoke-PnpmInstall with dev and global flag support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-PnpmInstall'
        $c | Should -Match '\[switch\]\$Dev'
    }
    It 'Provides pnrun alias for Invoke-PnpmRun script execution' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-PnpmRun'
        $c | Should -Match "Set-Alias -Name pnrun"
    }
}
