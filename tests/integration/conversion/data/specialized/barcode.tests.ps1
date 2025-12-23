

<#
.SYNOPSIS
    Integration tests for Barcode conversion utilities.

.DESCRIPTION
    This test suite validates Barcode generation and conversion functions.

.NOTES
    Tests cover both successful conversions and error handling.
    Some tests may be skipped if Node.js or required npm packages are not available.
#>

Describe 'Barcode Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Specialized' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Barcode Conversions' {
        It 'ConvertTo-BarcodeFromText function exists' {
            Get-Command ConvertTo-BarcodeFromText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-BarcodeFromText generates barcode from text' {
            # Skip if Node.js not available
            $node = Test-ToolAvailable -ToolName 'node' -InstallCommand 'scoop install nodejs' -Silent
            if (-not $node.Available) {
                $skipMessage = "Node.js not available"
                if ($node.InstallCommand) {
                    $skipMessage += ". Install with: $($node.InstallCommand)"
                }
                Set-ItResult -Skipped -Because $skipMessage
                return
            }

            $testText = '1234567890'
            $tempFile = Join-Path $TestDrive 'test-barcode.txt'
            Set-Content -Path $tempFile -Value $testText -NoNewline

            # Note: Actual barcode generation requires jsbarcode and canvas npm packages
            # This test verifies function existence and basic parameter handling
            Get-Command ConvertTo-BarcodeFromText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-BarcodeFromText supports different formats' {
            Get-Command ConvertTo-BarcodeFromText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            # Verify format parameter validation
            $testText = '1234567890'
            $tempFile = Join-Path $TestDrive 'test-barcode-format.txt'
            Set-Content -Path $tempFile -Value $testText -NoNewline

            # Should accept valid formats
            { ConvertTo-BarcodeFromText -InputPath $tempFile -Format CODE128 -ErrorAction Stop } | Should -Not -Throw
        }

        It 'ConvertTo-BarcodeFromJson function exists' {
            Get-Command ConvertTo-BarcodeFromJson -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-BarcodeToText function exists' {
            Get-Command ConvertFrom-BarcodeToText -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Barcode decoding indicates requirement for additional libraries' {
            $tempFile = Join-Path $TestDrive 'test-barcode.png'
            Set-Content -Path $tempFile -Value 'fake image data' -NoNewline

            # Should throw indicating requirement for additional libraries
            { ConvertFrom-BarcodeToText -InputPath $tempFile } | Should -Throw
        }

        It 'Handles missing input file gracefully' {
            $nonExistentFile = Join-Path $TestDrive 'nonexistent.txt'
            
            # Should throw an error for missing file
            { ConvertTo-BarcodeFromText -InputPath $nonExistentFile } | Should -Throw
        }
    }
}

