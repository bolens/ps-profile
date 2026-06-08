<#
tests/unit/profile-conversion-media-audio-video-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/audio/video.ps1'
}
Describe 'profile.d/conversion-modules/media/audio/video.ps1 extended scenarios' {
    It 'Documents video to audio extraction utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Video to Audio Extraction Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaAudioVideo'
    }
    It 'Defines ConvertFrom-VideoToAudio with FFmpeg extraction' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ConvertFrom-VideoToAudio'
        $c | Should -Match '_ConvertFrom-VideoToAudio'
        $c | Should -Match '_Ensure-Ffmpeg'
    }
    It 'Registers video-to-audio alias' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'video-to-audio'
        $c | Should -Match 'Set-AgentModeAlias -Name ''video-to-audio'''
    }
}

