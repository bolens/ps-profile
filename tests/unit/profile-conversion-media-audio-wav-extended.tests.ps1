<#
tests/unit/profile-conversion-media-audio-wav-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/audio/wav.ps1'
}
Describe 'profile.d/conversion-modules/media/audio/wav.ps1 extended scenarios' {
    It 'Documents WAV audio format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'WAV Audio Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaAudioWav'
    }
    It 'Defines WAV to MP3 and FLAC conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertFrom-WavToMp3'
        $c | Should -Match '_ConvertFrom-WavToFlac'
        $c | Should -Match '_Convert-AudioFormat'
    }
    It 'Registers wav-to-ogg and wav-to-opus entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'wav-to-ogg'
        $c | Should -Match 'ConvertFrom-WavToOpus'
        $c | Should -Match 'wav-to-opus'
    }
}

