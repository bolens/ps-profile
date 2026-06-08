<#
tests/unit/profile-deno-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/deno.ps1'
}
Describe 'profile.d/deno.ps1 extended scenarios' {
    It 'Declares standard tier for Deno runtime helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'PowerShell.Profile.Deno'
    }
    It 'Defines Invoke-Deno Invoke-DenoRun and Invoke-DenoTask wrappers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-DenoRun'
        $c | Should -Match 'Invoke-DenoTask'
    }
    It 'Registers deno deno-run and deno-task aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'deno'"
        $c | Should -Match "Set-AgentModeAlias -Name 'deno-run'"
    }
}
