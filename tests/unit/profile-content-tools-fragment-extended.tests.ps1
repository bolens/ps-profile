<#
tests/unit/profile-content-tools-fragment-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/content-tools.ps1'
}
Describe 'profile.d/content-tools.ps1 extended scenarios' {
    It 'Declares optional tier for content download tooling' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Tier: optional'
        $c | Should -Match 'yt-dlp'
        $c | Should -Match 'gallery-dl'
    }
    It 'Defines Download-Video wrapper using yt-dlp' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Download-Video'
        $c | Should -Match 'yt-dlp'
    }
    It 'Registers Download-Video with Set-AgentModeFunction and marks fragment loaded' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Set-AgentModeFunction -Name ''Download-Video'''
        $c | Should -Match "Set-FragmentLoaded -FragmentName 'content-tools'"
    }
}
