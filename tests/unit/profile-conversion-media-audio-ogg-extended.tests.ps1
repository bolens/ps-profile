<#
tests/unit/profile-conversion-media-audio-ogg-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/audio/ogg.ps1'
}
Describe 'profile.d/conversion-modules/media/audio/ogg.ps1 extended scenarios' {
    It 'Documents OGG Vorbis audio format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'OGG Vorbis Audio Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaAudioOgg'
    }
    It 'Defines OGG to WAV and FLAC conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertFrom-OggToWav'
        $c | Should -Match '_ConvertFrom-OggToFlac'
        $c | Should -Match '_Convert-AudioFormat'
    }
    It 'Registers ogg-to-mp3 and ogg-to-opus entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ogg-to-mp3'
        $c | Should -Match 'ConvertFrom-OggToOpus'
        $c | Should -Match 'ogg-to-opus'
    }
}

