<#
tests/unit/profile-angular-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/angular.ps1'
}
Describe 'profile.d/angular.ps1 extended scenarios' {
    It 'Declares standard tier for Angular CLI helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'PowerShell.Profile.Angular'
    }
    It 'Defines Invoke-Angular preferring npx @angular/cli' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-Angular'
        $c | Should -Match '@angular/cli'
    }
    It 'Registers ng and ng-new aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'ng'"
        $c | Should -Match "Set-AgentModeAlias -Name 'ng-new'"
    }
}
