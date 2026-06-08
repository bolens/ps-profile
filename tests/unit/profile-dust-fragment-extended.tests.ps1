<#
tests/unit/profile-dust-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/dust.ps1'
}
Describe 'profile.d/dust.ps1 extended scenarios' {
    It 'Declares standard tier guarded by dust availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'Test-CachedCommand dust'
    }
    It 'Aliases du and diskusage to dust when command is available' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-Alias -Name du -Value dust"
        $c | Should -Match "Set-Alias -Name diskusage -Value dust"
    }
    It 'Calls Invoke-MissingToolWarning when dust is unavailable' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Invoke-MissingToolWarning'
        $c | Should -Match "ToolName 'dust'"
    }
}
