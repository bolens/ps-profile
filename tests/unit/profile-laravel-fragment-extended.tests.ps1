<#
tests/unit/profile-laravel-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/laravel.ps1'
}
Describe 'profile.d/laravel.ps1 extended scenarios' {
    It 'Declares standard tier for web and development Laravel helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Environment: web, development'
    }
    It 'Defines Invoke-LaravelArtisan wrapping artisan commands' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-LaravelArtisan'
        $c | Should -Match 'artisan'
    }
    It 'Registers artisan and laravel-new aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'artisan'"
        $c | Should -Match "Set-AgentModeAlias -Name 'laravel-new'"
    }
}
