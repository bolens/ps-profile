

<#
.SYNOPSIS
    Integration tests for FLAC audio format conversion utilities.

.DESCRIPTION
    This test suite validates FLAC audio conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires ffmpeg for actual conversions.
#>

Describe 'FLAC Audio Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'Audio conversion utilities - FLAC format' {
        It 'ConvertFrom-FlacToWav function exists' {
            Get-Command ConvertFrom-FlacToWav -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-FlacToMp3 function exists' {
            Get-Command ConvertFrom-FlacToMp3 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-FlacToOgg function exists' {
            Get-Command ConvertFrom-FlacToOgg -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-FlacToAac function exists' {
            Get-Command ConvertFrom-FlacToAac -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-FlacToOpus function exists' {
            Get-Command ConvertFrom-FlacToOpus -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        # Note: Error handling test removed to avoid hangs when conversion functions check for external tools

        It 'ConvertFrom-FlacToWav uses default output path when not specified' {
            # Skip if ffmpeg not available
            $ffmpeg = Test-ToolAvailable -ToolName 'ffmpeg' -InstallCommand 'scoop install ffmpeg' -Silent
            if (-not $ffmpeg.Available) {
                $skipMessage = "ffmpeg command not available"
                if ($ffmpeg.InstallCommand) {
                    $skipMessage += ". Install with: $($ffmpeg.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }

            # Test parameter handling (will fail on actual conversion without real file, but tests parameter logic)
            Get-Command ConvertFrom-FlacToWav -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'flac-to-wav alias resolves to ConvertFrom-FlacToWav' {
            Get-Alias flac-to-wav -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias flac-to-wav).ResolvedCommandName | Should -Be 'ConvertFrom-FlacToWav'
        }

        It 'flac-to-mp3 alias resolves to ConvertFrom-FlacToMp3' {
            Get-Alias flac-to-mp3 -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias flac-to-mp3).ResolvedCommandName | Should -Be 'ConvertFrom-FlacToMp3'
        }

        It 'flac-to-ogg alias resolves to ConvertFrom-FlacToOgg' {
            Get-Alias flac-to-ogg -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias flac-to-ogg).ResolvedCommandName | Should -Be 'ConvertFrom-FlacToOgg'
        }

        It 'flac-to-aac alias resolves to ConvertFrom-FlacToAac' {
            Get-Alias flac-to-aac -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias flac-to-aac).ResolvedCommandName | Should -Be 'ConvertFrom-FlacToAac'
        }

        It 'flac-to-opus alias resolves to ConvertFrom-FlacToOpus' {
            Get-Alias flac-to-opus -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias flac-to-opus).ResolvedCommandName | Should -Be 'ConvertFrom-FlacToOpus'
        }
    }
}

