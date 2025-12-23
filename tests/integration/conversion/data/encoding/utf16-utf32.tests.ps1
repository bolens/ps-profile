

<#
.SYNOPSIS
    Integration tests for UTF-16 and UTF-32 encoding conversion utilities.

.DESCRIPTION
    This test suite validates UTF-16 and UTF-32 encoding conversion functions including conversions to/from ASCII, Hex, and Base64.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'UTF-16 and UTF-32 Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'UTF-16 Encoding Conversions' {
        It 'ConvertFrom-AsciiToUtf16 converts ASCII to UTF-16' {
            $testString = 'Hello'
            $result = $testString | ConvertFrom-AsciiToUtf16
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            # UTF-16 for "Hello" should be 10 hex characters (5 chars * 2 bytes)
            # Allow for BOM or slight variations
            $result.Length | Should -BeGreaterOrEqual 10
        }
        
        It 'ConvertFrom-Utf16ToAscii converts UTF-16 to ASCII' {
            # UTF-16 hex for "Hello" (little-endian): 4800 6500 6C00 6C00 6F00
            $testUtf16 = '480065006C006C006F00'
            $result = $testUtf16 | ConvertFrom-Utf16ToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Be 'Hello'
        }
        
        It 'ASCII to UTF-16 and back roundtrip' {
            $original = 'Hello World'
            $utf16 = $original | ConvertFrom-AsciiToUtf16
            $decoded = $utf16 | ConvertFrom-Utf16ToAscii
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-HexToUtf16 converts Hex to UTF-16' {
            $testHex = '48656C6C6F'
            $result = $testHex | ConvertFrom-HexToUtf16
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Utf16ToHex converts UTF-16 to Hex' {
            $testUtf16 = '480065006C006C006F00'
            $result = $testUtf16 | ConvertFrom-Utf16ToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Hex to UTF-16 and back roundtrip' {
            $original = '48656C6C6F'
            $utf16 = $original | ConvertFrom-HexToUtf16
            $hex = $utf16 | ConvertFrom-Utf16ToHex
            $hex | Should -Be $original
        }
        
        It 'ConvertFrom-Base64ToUtf16 converts Base64 to UTF-16' {
            $testBase64 = 'SGVsbG8gV29ybGQ='
            $result = $testBase64 | ConvertFrom-Base64ToUtf16
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Utf16ToBase64 converts UTF-16 to Base64' {
            $testUtf16 = '480065006C006C006F00'
            $result = $testUtf16 | ConvertFrom-Utf16ToBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Base64 to UTF-16 and back roundtrip' {
            $original = 'SGVsbG8gV29ybGQ='
            $utf16 = $original | ConvertFrom-Base64ToUtf16
            $base64 = $utf16 | ConvertFrom-Utf16ToBase64
            $base64 | Should -Be $original
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToUtf16
            $result | Should -Be ''
        }
    }

    Context 'UTF-32 Encoding Conversions' {
        It 'ConvertFrom-AsciiToUtf32 converts ASCII to UTF-32' {
            $testString = 'Hello'
            $result = $testString | ConvertFrom-AsciiToUtf32
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            # UTF-32 for "Hello" should be 20 hex characters (5 chars * 4 bytes)
            # Allow for slight variations
            $result.Length | Should -BeGreaterOrEqual 20
        }
        
        It 'ConvertFrom-Utf32ToAscii converts UTF-32 to ASCII' {
            # UTF-32 hex for "Hello" (little-endian): 48000000 65000000 6C000000 6C000000 6F000000
            $testUtf32 = '48000000650000006C0000006C0000006F000000'
            $result = $testUtf32 | ConvertFrom-Utf32ToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Be 'Hello'
        }
        
        It 'ASCII to UTF-32 and back roundtrip' {
            $original = 'Hello World'
            $utf32 = $original | ConvertFrom-AsciiToUtf32
            $decoded = $utf32 | ConvertFrom-Utf32ToAscii
            $decoded | Should -Be $original
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToUtf32
            $result | Should -Be ''
        }
    }
}

