<#
tests/unit/profile-conversion-media-audio-common-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/audio/common.ps1'
}
Describe 'profile.d/conversion-modules/media/audio/common.ps1 extended scenarios' {
    It 'Documents shared audio conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Audio media format conversion utilities - Common Helpers'
        $c | Should -Match 'Shared helper functions for all audio format conversions'
    }
    It 'Defines Initialize-FileConversion-MediaAudioCommon with FFmpeg helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-MediaAudioCommon'
        $c | Should -Match '_Ensure-Ffmpeg'
        $c | Should -Match 'Test-CachedCommand ''ffmpeg'''
    }
    It 'Provides _Convert-AudioFormat with codec and options support' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_Convert-AudioFormat'
        $c | Should -Match '-acodec'
        $c | Should -Match 'Get-ConversionToolMissingMessage'
    }
}

