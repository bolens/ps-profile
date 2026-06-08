<#
tests/unit/profile-vue-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/vue.ps1'
}
Describe 'profile.d/vue.ps1 extended scenarios' {
    It 'Declares standard tier for Vue.js CLI helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'PowerShell.Profile.Vue'
    }
    It 'Defines Invoke-Vue preferring npx @vue/cli with global fallback' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-Vue'
        $c | Should -Match '@vue/cli'
    }
    It 'Registers vue and vue-create aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'vue'"
        $c | Should -Match "Set-AgentModeAlias -Name 'vue-create'"
    }
}
