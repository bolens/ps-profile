<#
tests/unit/profile-lazydocker-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/lazydocker.ps1'
}
Describe 'profile.d/lazydocker.ps1 extended scenarios' {
    It 'Declares essential tier for Docker terminal UI helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'lazydocker helper'
    }
    It 'Defines Invoke-LazyDocker guarded by Test-CachedCommand lazydocker' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-LazyDocker'
        $c | Should -Match 'Test-CachedCommand lazydocker'
    }
    It 'Registers ld shorthand alias and documents PowerShell.Profile.LazyDocker' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'ld'"
        $c | Should -Match 'PowerShell.Profile.LazyDocker'
    }
}
