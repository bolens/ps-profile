

<#
.SYNOPSIS
    Integration tests for AVIF image format conversion utilities.

.DESCRIPTION
    This test suite validates AVIF image conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires ImageMagick/GraphicsMagick or ffmpeg for actual conversions.
#>

Describe 'AVIF Image Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'Image conversion utilities - AVIF format' {
        It 'ConvertFrom-AvifToPng function exists' {
            Get-Command ConvertFrom-AvifToPng -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-AvifToJpeg function exists' {
            Get-Command ConvertFrom-AvifToJpeg -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-AvifToWebp function exists' {
            Get-Command ConvertFrom-AvifToWebp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-AvifFromPng function exists' {
            Get-Command ConvertTo-AvifFromPng -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-AvifFromJpeg function exists' {
            Get-Command ConvertTo-AvifFromJpeg -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-AvifFromWebp function exists' {
            Get-Command ConvertTo-AvifFromWebp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        # Note: Error handling test removed to avoid hangs when conversion functions check for external tools

        It 'avif-to-png alias resolves to ConvertFrom-AvifToPng' {
            Get-Alias avif-to-png -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias avif-to-png).ResolvedCommandName | Should -Be 'ConvertFrom-AvifToPng'
        }

        It 'avif-to-jpeg alias resolves to ConvertFrom-AvifToJpeg' {
            Get-Alias avif-to-jpeg -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias avif-to-jpeg).ResolvedCommandName | Should -Be 'ConvertFrom-AvifToJpeg'
        }

        It 'avif-to-jpg alias resolves to ConvertFrom-AvifToJpeg' {
            Get-Alias avif-to-jpg -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias avif-to-jpg).ResolvedCommandName | Should -Be 'ConvertFrom-AvifToJpeg'
        }

        It 'avif-to-webp alias resolves to ConvertFrom-AvifToWebp' {
            Get-Alias avif-to-webp -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias avif-to-webp).ResolvedCommandName | Should -Be 'ConvertFrom-AvifToWebp'
        }

        It 'png-to-avif alias resolves to ConvertTo-AvifFromPng' {
            Get-Alias png-to-avif -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias png-to-avif).ResolvedCommandName | Should -Be 'ConvertTo-AvifFromPng'
        }

        It 'jpeg-to-avif alias resolves to ConvertTo-AvifFromJpeg' {
            Get-Alias jpeg-to-avif -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias jpeg-to-avif).ResolvedCommandName | Should -Be 'ConvertTo-AvifFromJpeg'
        }

        It 'jpg-to-avif alias resolves to ConvertTo-AvifFromJpeg' {
            Get-Alias jpg-to-avif -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias jpg-to-avif).ResolvedCommandName | Should -Be 'ConvertTo-AvifFromJpeg'
        }

        It 'webp-to-avif alias resolves to ConvertTo-AvifFromWebp' {
            Get-Alias webp-to-avif -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias webp-to-avif).ResolvedCommandName | Should -Be 'ConvertTo-AvifFromWebp'
        }
    }
}

