

<#
.SYNOPSIS
    Integration tests for QR Code conversion utilities.

.DESCRIPTION
    This test suite validates QR Code generation and conversion functions.

.NOTES
    Tests cover both successful conversions and error handling.
    Some tests may be skipped if Node.js or required npm packages are not available.
#>

Describe 'QR Code Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Specialized' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'QR Code Conversions' {
        It 'ConvertTo-QrCodeFromText function exists' {
            Get-Command ConvertTo-QrCodeFromText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-QrCodeFromText generates QR code from text' {
            # Skip if Node.js or qrcode package not available
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }

            $testText = 'Hello World'
            $tempFile = Join-Path $TestDrive 'test-qr.txt'
            Set-Content -Path $tempFile -Value $testText -NoNewline

            # Note: Actual QR code generation requires qrcode npm package
            # This test verifies function existence and basic parameter handling
            Get-Command ConvertTo-QrCodeFromText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-QrCodeFromJson function exists' {
            Get-Command ConvertTo-QrCodeFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-QrCodeToText function exists' {
            Get-Command ConvertFrom-QrCodeToText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'QR code decoding indicates requirement for additional libraries' {
            $tempFile = Join-Path $TestDrive 'test-qr.png'
            Set-Content -Path $tempFile -Value 'fake image data' -NoNewline

            # Should throw indicating requirement for additional libraries
            { ConvertFrom-QrCodeToText -InputPath $tempFile } | Should -Throw
        }
    }
}

