<#
tests/unit/profile-winget-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/winget.ps1'
}
Describe 'profile.d/winget.ps1 extended scenarios' {
    It 'Declares standard tier guarded by winget availability' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: standard'
        $c | Should -Match 'if \(Test-CachedCommand winget\)'
    }
    It 'Defines Test-WingetOutdated wrapping winget upgrade listing' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Test-WingetOutdated'
        $c | Should -Match 'winget upgrade'
    }
    It 'Registers winget-outdated and winget-update aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match "Set-AgentModeAlias -Name 'winget-outdated'"
        $c | Should -Match "Set-AgentModeAlias -Name 'winget-update'"
    }
}
