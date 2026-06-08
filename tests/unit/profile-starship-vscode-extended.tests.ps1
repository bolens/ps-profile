<#
tests/unit/profile-starship-vscode-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/starship/StarshipVSCode.ps1'
}
Describe 'profile.d/starship/StarshipVSCode.ps1 extended scenarios' {
    It 'Documents VS Code integration for Starship prompt tracking' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'VS Code integration'
        $c | Should -Match 'integrated terminal'
    }
    It 'Defines Update-VSCodePrompt to sync OriginalPrompt state' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Update-VSCodePrompt'
        $c | Should -Match '__VSCodeState'
        $c | Should -Match 'OriginalPrompt'
    }
    It 'Logs debug message when PS_PROFILE_DEBUG is enabled' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PS_PROFILE_DEBUG'
        $c | Should -Match 'Updated VS Code OriginalPrompt'
    }
}
