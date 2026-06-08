<#
tests/unit/profile-conversion-media-audio-flac-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/audio/flac.ps1'
}
Describe 'profile.d/conversion-modules/media/audio/flac.ps1 extended scenarios' {
    It 'Documents FLAC audio format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'FLAC Audio Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaAudioFlac'
    }
    It 'Defines FLAC to WAV and MP3 conversion helpers' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match '_ConvertFrom-FlacToWav'
        $c | Should -Match '_ConvertFrom-FlacToMp3'
        $c | Should -Match '_Convert-AudioFormat'
    }
    It 'Registers flac-to-wav and flac-to-opus aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'flac-to-wav'
        $c | Should -Match 'ConvertFrom-FlacToOpus'
        $c | Should -Match 'flac-to-opus'
    }
}

