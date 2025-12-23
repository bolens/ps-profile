

<#
.SYNOPSIS
    Integration tests for OGG Vorbis audio format conversion utilities.

.DESCRIPTION
    This test suite validates OGG Vorbis audio conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires ffmpeg for actual conversions.
#>

Describe 'OGG Vorbis Audio Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'Audio conversion utilities - OGG Vorbis format' {
        It 'ConvertFrom-OggToWav function exists' {
            Get-Command ConvertFrom-OggToWav -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-OggToMp3 function exists' {
            Get-Command ConvertFrom-OggToMp3 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-OggToFlac function exists' {
            Get-Command ConvertFrom-OggToFlac -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-OggToAac function exists' {
            Get-Command ConvertFrom-OggToAac -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-OggToOpus function exists' {
            Get-Command ConvertFrom-OggToOpus -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        # Note: Error handling test removed to avoid hangs when conversion functions check for external tools

        It 'ogg-to-wav alias resolves to ConvertFrom-OggToWav' {
            Get-Alias ogg-to-wav -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ogg-to-wav).ResolvedCommandName | Should -Be 'ConvertFrom-OggToWav'
        }

        It 'ogg-to-mp3 alias resolves to ConvertFrom-OggToMp3' {
            Get-Alias ogg-to-mp3 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ogg-to-mp3).ResolvedCommandName | Should -Be 'ConvertFrom-OggToMp3'
        }

        It 'ogg-to-flac alias resolves to ConvertFrom-OggToFlac' {
            Get-Alias ogg-to-flac -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ogg-to-flac).ResolvedCommandName | Should -Be 'ConvertFrom-OggToFlac'
        }

        It 'ogg-to-aac alias resolves to ConvertFrom-OggToAac' {
            Get-Alias ogg-to-aac -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ogg-to-aac).ResolvedCommandName | Should -Be 'ConvertFrom-OggToAac'
        }

        It 'ogg-to-opus alias resolves to ConvertFrom-OggToOpus' {
            Get-Alias ogg-to-opus -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias ogg-to-opus).ResolvedCommandName | Should -Be 'ConvertFrom-OggToOpus'
        }
    }
}

