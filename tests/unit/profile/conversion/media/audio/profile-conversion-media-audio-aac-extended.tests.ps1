<#
tests/unit/profile-conversion-media-audio-aac-extended.tests.ps1
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
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/conversion-modules/media/audio/aac.ps1'
}
Describe 'profile.d/conversion-modules/media/audio/aac.ps1 extended scenarios' {
    It 'Documents AAC audio format conversion utilities' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'AAC Audio Format Conversion Utilities'
        $c | Should -Match 'Initialize-FileConversion-MediaAudioAac'
    }
    It 'Initializes AAC conversions via common audio helper' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Initialize-FileConversion-MediaAudioCommon'
        $c | Should -Match '_ConvertFrom-AacToWav'
        $c | Should -Match 'libmp3lame'
    }
    It 'Registers aac-to-wav and aac-to-mp3 entry points' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'ConvertFrom-AacToWav'
        $c | Should -Match 'aac-to-wav'
        $c | Should -Match 'aac-to-mp3'
    }
}

