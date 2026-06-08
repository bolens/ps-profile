<#
tests/unit/profile-starship-smart-prompt-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/starship/SmartPrompt.ps1'
}
Describe 'profile.d/starship/SmartPrompt.ps1 extended scenarios' {
    It 'Documents smart fallback prompt when Starship is unavailable' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Smart fallback prompt'
        $c | Should -Match 'Starship is not available'
    }
    It 'Defines Initialize-SmartPrompt with idempotent SmartPromptInitialized guard' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-SmartPrompt'
        $c | Should -Match 'SmartPromptInitialized'
        $c | Should -Match 'OriginalPrompt'
    }
    It 'Supports optional project status via PS_PROFILE_SHOW environment flags' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'PS_PROFILE_SHOW_GIT_BRANCH'
        $c | Should -Match 'PS_PROFILE_SHOW_UV'
        $c | Should -Match 'PS_PROFILE_SHOW_DOCKER'
    }
}
