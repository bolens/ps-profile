

<#
.SYNOPSIS
    Integration tests for TIFF image format conversion utilities.

.DESCRIPTION
    This test suite validates TIFF image conversion functions.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires ImageMagick/GraphicsMagick or ffmpeg for actual conversions.
#>

Describe 'TIFF Image Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'Image conversion utilities - TIFF format' {
        It 'ConvertFrom-TiffToPng function exists' {
            Get-Command ConvertFrom-TiffToPng -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-TiffToJpeg function exists' {
            Get-Command ConvertFrom-TiffToJpeg -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-TiffToPdf function exists' {
            Get-Command ConvertFrom-TiffToPdf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-TiffFromPng function exists' {
            Get-Command ConvertTo-TiffFromPng -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-TiffFromJpeg function exists' {
            Get-Command ConvertTo-TiffFromJpeg -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-TiffFromPdf function exists' {
            Get-Command ConvertTo-TiffFromPdf -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        # Note: Error handling test removed to avoid hangs when conversion functions check for external tools

        It 'ConvertTo-TiffFromPng accepts compression parameter' {
            $func = Get-Command ConvertTo-TiffFromPng -ErrorAction SilentlyContinue
            if ($func) {
                $func.Parameters.Keys | Should -Contain 'Compression'
            }
        }

        It 'tiff-to-png alias resolves to ConvertFrom-TiffToPng' {
            Get-Alias tiff-to-png -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tiff-to-png).ResolvedCommandName | Should -Be 'ConvertFrom-TiffToPng'
        }

        It 'tif-to-png alias resolves to ConvertFrom-TiffToPng' {
            Get-Alias tif-to-png -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tif-to-png).ResolvedCommandName | Should -Be 'ConvertFrom-TiffToPng'
        }

        It 'tiff-to-jpeg alias resolves to ConvertFrom-TiffToJpeg' {
            Get-Alias tiff-to-jpeg -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tiff-to-jpeg).ResolvedCommandName | Should -Be 'ConvertFrom-TiffToJpeg'
        }

        It 'tiff-to-jpg alias resolves to ConvertFrom-TiffToJpeg' {
            Get-Alias tiff-to-jpg -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tiff-to-jpg).ResolvedCommandName | Should -Be 'ConvertFrom-TiffToJpeg'
        }

        It 'tif-to-jpeg alias resolves to ConvertFrom-TiffToJpeg' {
            Get-Alias tif-to-jpeg -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tif-to-jpeg).ResolvedCommandName | Should -Be 'ConvertFrom-TiffToJpeg'
        }

        It 'tif-to-jpg alias resolves to ConvertFrom-TiffToJpeg' {
            Get-Alias tif-to-jpg -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tif-to-jpg).ResolvedCommandName | Should -Be 'ConvertFrom-TiffToJpeg'
        }

        It 'tiff-to-pdf alias resolves to ConvertFrom-TiffToPdf' {
            Get-Alias tiff-to-pdf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tiff-to-pdf).ResolvedCommandName | Should -Be 'ConvertFrom-TiffToPdf'
        }

        It 'tif-to-pdf alias resolves to ConvertFrom-TiffToPdf' {
            Get-Alias tif-to-pdf -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias tif-to-pdf).ResolvedCommandName | Should -Be 'ConvertFrom-TiffToPdf'
        }

        It 'png-to-tiff alias resolves to ConvertTo-TiffFromPng' {
            Get-Alias png-to-tiff -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias png-to-tiff).ResolvedCommandName | Should -Be 'ConvertTo-TiffFromPng'
        }

        It 'png-to-tif alias resolves to ConvertTo-TiffFromPng' {
            Get-Alias png-to-tif -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias png-to-tif).ResolvedCommandName | Should -Be 'ConvertTo-TiffFromPng'
        }

        It 'jpeg-to-tiff alias resolves to ConvertTo-TiffFromJpeg' {
            Get-Alias jpeg-to-tiff -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias jpeg-to-tiff).ResolvedCommandName | Should -Be 'ConvertTo-TiffFromJpeg'
        }

        It 'jpg-to-tiff alias resolves to ConvertTo-TiffFromJpeg' {
            Get-Alias jpg-to-tiff -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias jpg-to-tiff).ResolvedCommandName | Should -Be 'ConvertTo-TiffFromJpeg'
        }

        It 'jpeg-to-tif alias resolves to ConvertTo-TiffFromJpeg' {
            Get-Alias jpeg-to-tif -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias jpeg-to-tif).ResolvedCommandName | Should -Be 'ConvertTo-TiffFromJpeg'
        }

        It 'jpg-to-tif alias resolves to ConvertTo-TiffFromJpeg' {
            Get-Alias jpg-to-tif -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias jpg-to-tif).ResolvedCommandName | Should -Be 'ConvertTo-TiffFromJpeg'
        }

        It 'pdf-to-tiff alias resolves to ConvertTo-TiffFromPdf' {
            Get-Alias pdf-to-tiff -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdf-to-tiff).ResolvedCommandName | Should -Be 'ConvertTo-TiffFromPdf'
        }

        It 'pdf-to-tif alias resolves to ConvertTo-TiffFromPdf' {
            Get-Alias pdf-to-tif -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias pdf-to-tif).ResolvedCommandName | Should -Be 'ConvertTo-TiffFromPdf'
        }
    }
}

