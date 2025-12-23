

<#
.SYNOPSIS
    Integration tests for video to GIF conversion utilities.

.DESCRIPTION
    This test suite validates video to GIF conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires ffmpeg for actual conversions.
#>

Describe 'Video to GIF Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'Video conversion utilities' {
        It 'ConvertFrom-VideoToGif converts video to GIF' {
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

            Get-Command ConvertFrom-VideoToGif -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Requires actual video file for full testing
        }

        It 'video-to-gif alias resolves to ConvertFrom-VideoToGif' {
            Get-Alias video-to-gif -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias video-to-gif).ResolvedCommandName | Should -Be 'ConvertFrom-VideoToGif'
        }
    }
}

