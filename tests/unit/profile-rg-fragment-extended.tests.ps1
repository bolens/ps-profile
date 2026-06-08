<#
tests/unit/profile-rg-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/rg.ps1'
}
Describe 'profile.d/rg.ps1 extended scenarios' {
    It 'Declares essential tier for ripgrep search helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: essential'
        $c | Should -Match 'ripgrep helper'
    }
    It 'Defines Find-RipgrepText with mandatory Pattern parameter' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Find-RipgrepText'
        $c | Should -Match 'Test-CachedCommand'
    }
    It 'Registers rgf alias and documents PowerShell.Profile.Ripgrep' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'rgf'"
        $c | Should -Match 'PowerShell.Profile.Ripgrep'
    }
}
