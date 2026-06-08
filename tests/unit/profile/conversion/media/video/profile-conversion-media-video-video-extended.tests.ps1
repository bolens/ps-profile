<#
tests/unit/profile-conversion-media-video-video-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/video/video.ps1'
}
Describe 'profile.d/conversion-modules/media/video/video.ps1 extended scenarios' {
    It 'Documents video media format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Video media format conversion utilities'
        $c | Should -Match 'Video to GIF conversion'
    }
    It 'Defines Initialize-FileConversion-MediaVideo with GIF conversion' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-MediaVideo'
        $c | Should -Match 'ConvertFrom-VideoToGif'
    }
    It 'Registers video-to-gif alias' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'video-to-gif'
        $c | Should -Match 'Set-AgentModeAlias -Name ''video-to-gif'''
    }
}

