<#
tests/unit/profile-php-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/php.ps1'
}
Describe 'profile.d/php.ps1 extended scenarios' {
    It 'Declares standard tier for PHP and Composer helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'PowerShell.Profile.Php'
    }
    It 'Defines Invoke-Php and Invoke-Composer CLI wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-Php'
        $c | Should -Match 'Invoke-Composer'
    }
    It 'Registers php composer and composer-require aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'php'"
        $c | Should -Match "Set-AgentModeAlias -Name 'composer-require'"
    }
}
