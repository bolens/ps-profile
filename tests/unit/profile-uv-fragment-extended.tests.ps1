<#
tests/unit/profile-uv-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/uv.ps1'
}
Describe 'profile.d/uv.ps1 extended scenarios' {
    It 'Declares standard tier guarded by uv availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand uv\)'
    }
    It 'Defines Invoke-Pip delegating to uv pip for faster installs' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'function Invoke-Pip'
        $c | Should -Match 'uv pip'
    }
    It 'Registers pip and uvrun aliases via Set-AgentModeAlias' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'pip'"
        $c | Should -Match "Set-AgentModeAlias -Name 'uvrun'"
    }
}
