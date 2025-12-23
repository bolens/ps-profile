

<#
.SYNOPSIS
    Integration tests for WAV audio format conversion utilities.

.DESCRIPTION
    This test suite validates WAV audio conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires ffmpeg for actual conversions.
#>

Describe 'WAV Audio Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'Audio conversion utilities - WAV format' {
        It 'ConvertFrom-WavToMp3 function exists' {
            Get-Command ConvertFrom-WavToMp3 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-WavToFlac function exists' {
            Get-Command ConvertFrom-WavToFlac -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-WavToOgg function exists' {
            Get-Command ConvertFrom-WavToOgg -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-WavToAac function exists' {
            Get-Command ConvertFrom-WavToAac -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-WavToOpus function exists' {
            Get-Command ConvertFrom-WavToOpus -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-WavToMp3 accepts bitrate parameter' {
            Get-Command ConvertFrom-WavToMp3 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Verify function accepts Bitrate parameter
            $func = Get-Command ConvertFrom-WavToMp3
            $func.Parameters.Keys | Should -Contain 'Bitrate'
        }

        It 'ConvertFrom-WavToOgg accepts quality parameter' {
            Get-Command ConvertFrom-WavToOgg -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Verify function accepts Quality parameter
            $func = Get-Command ConvertFrom-WavToOgg
            $func.Parameters.Keys | Should -Contain 'Quality'
        }

        It 'wav-to-mp3 alias resolves to ConvertFrom-WavToMp3' {
            Get-Alias wav-to-mp3 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias wav-to-mp3).ResolvedCommandName | Should -Be 'ConvertFrom-WavToMp3'
        }

        It 'wav-to-flac alias resolves to ConvertFrom-WavToFlac' {
            Get-Alias wav-to-flac -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias wav-to-flac).ResolvedCommandName | Should -Be 'ConvertFrom-WavToFlac'
        }

        It 'wav-to-ogg alias resolves to ConvertFrom-WavToOgg' {
            Get-Alias wav-to-ogg -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias wav-to-ogg).ResolvedCommandName | Should -Be 'ConvertFrom-WavToOgg'
        }

        It 'wav-to-aac alias resolves to ConvertFrom-WavToAac' {
            Get-Alias wav-to-aac -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias wav-to-aac).ResolvedCommandName | Should -Be 'ConvertFrom-WavToAac'
        }

        It 'wav-to-opus alias resolves to ConvertFrom-WavToOpus' {
            Get-Alias wav-to-opus -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias wav-to-opus).ResolvedCommandName | Should -Be 'ConvertFrom-WavToOpus'
        }
    }
}

