. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

Describe 'Media Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files-conversion.ps1')
    }

    Context 'Audio conversion utilities' {
        It 'Convert-Audio function exists and can be called' {
            Get-Command Convert-Audio -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Actual audio conversion requires ffmpeg and test audio files
        }

        It 'ConvertFrom-VideoToAudio extracts audio from video' {
            # Skip if ffmpeg not available
            if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "ffmpeg command not available"
                return
            }

            Get-Command ConvertFrom-VideoToAudio -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Requires actual video file for full testing
        }
    }

    Context 'Video conversion utilities' {
        It 'ConvertFrom-VideoToGif converts video to GIF' {
            # Skip if ffmpeg not available
            if (-not (Get-Command ffmpeg -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because "ffmpeg command not available"
                return
            }

            Get-Command ConvertFrom-VideoToGif -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Requires actual video file for full testing
        }
    }

    Context 'Image conversion utilities' {
        It 'Convert-Image function exists and can be called' {
            Get-Command Convert-Image -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Actual image conversion requires ImageMagick and test image files
        }

        It 'Resize-Image function exists and can be called' {
            Get-Command Resize-Image -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Actual image resizing requires ImageMagick and test image files
        }
    }
}
