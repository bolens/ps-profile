<#
tests/unit/profile-system-editor-aliases-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/system/EditorAliases.ps1'
}
Describe 'profile.d/system/EditorAliases.ps1 extended scenarios' {
    It 'Documents editor alias utilities for Neovim' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Editor alias utilities'
        $c | Should -Match 'Neovim'
    }
    It 'Defines Open-Neovim guarded by Test-CachedCommand nvim' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Open-Neovim'
        $c | Should -Match "Test-CachedCommand 'nvim'"
        $c | Should -Match 'Invoke-WithWideEvent'
    }
    It 'Registers vim and vi aliases targeting Neovim helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'vim'"
        $c | Should -Match "Set-AgentModeAlias -Name 'vi'"
    }
}
