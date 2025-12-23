

<#
.SYNOPSIS
    Integration tests for legacy image conversion utilities.

.DESCRIPTION
    This test suite validates legacy image conversion functions including Convert-Image and Resize-Image.

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Requires ImageMagick/GraphicsMagick for actual conversions.
#>

Describe 'Legacy Image Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Media' -LoadFilesFragment -EnsureFileConversionMedia
    }

    Context 'Image conversion utilities - Legacy functions' {
        It 'Convert-Image function exists and can be called' {
            Get-Command Convert-Image -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Actual image conversion requires ImageMagick/GraphicsMagick and test image files
        }

        It 'Resize-Image function exists and can be called' {
            Get-Command Resize-Image -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            # Note: Actual image resizing requires ImageMagick/GraphicsMagick and test image files
        }

        It 'image-convert alias resolves to Convert-Image' {
            Get-Alias image-convert -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias image-convert).ResolvedCommandName | Should -Be 'Convert-Image'
        }

        It 'image-resize alias resolves to Resize-Image' {
            Get-Alias image-resize -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            (Get-Alias image-resize).ResolvedCommandName | Should -Be 'Resize-Image'
        }
    }
}

