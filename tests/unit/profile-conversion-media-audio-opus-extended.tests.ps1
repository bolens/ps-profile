<#
tests/unit/profile-conversion-media-audio-opus-extended.tests.ps1
#>
BeforeAll {
    . $PSScriptRoot/../TestSupport.ps1
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/audio/opus.ps1'
}
Describe 'profile.d/conversion-modules/media/audio/opus.ps1 extended scenarios' {
    It 'Documents Opus audio format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Opus Audio Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaAudioOpus'
    }
    It 'Defines Opus to WAV and MP3 conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertFrom-OpusToWav'
        $c | Should -Match '_ConvertFrom-OpusToMp3'
        $c | Should -Match '_Convert-AudioFormat'
    }
    It 'Registers opus-to-flac and opus-to-aac aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'opus-to-flac'
        $c | Should -Match 'ConvertFrom-OpusToAac'
        $c | Should -Match 'opus-to-aac'
    }
}

