<#
tests/unit/profile-starship-smart-prompt-extended.tests.ps1
#>
BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
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
