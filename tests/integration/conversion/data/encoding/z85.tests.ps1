

<#
.SYNOPSIS
    Integration tests for Z85 encoding conversion utilities.

.DESCRIPTION
    This test suite validates Z85 encoding conversion functions including conversions to/from ASCII, Hex, and Base64.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Z85 Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Z85 Encoding Conversions' {
        It 'ConvertFrom-AsciiToZ85 converts ASCII to Z85' {
            $testString = 'Hello World'
            $result = $testString | ConvertFrom-AsciiToZ85
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Z85ToAscii converts Z85 to ASCII' {
            $testZ85 = 'nm=QNzY&b0A'
            $result = $testZ85 | ConvertFrom-Z85ToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ASCII to Z85 and back roundtrip' {
            $original = 'Hello World'
            $z85 = $original | ConvertFrom-AsciiToZ85
            $decoded = $z85 | ConvertFrom-Z85ToAscii
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-HexToZ85 converts Hex to Z85' {
            $testHex = '48656C6C6F'
            $result = $testHex | ConvertFrom-HexToZ85
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Z85ToHex converts Z85 to Hex' {
            $testZ85 = 'nm=QNzY'
            $result = $testZ85 | ConvertFrom-Z85ToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Hex to Z85 and back roundtrip' {
            $original = '48656C6C6F'
            $z85 = $original | ConvertFrom-HexToZ85
            $decoded = $z85 | ConvertFrom-Z85ToHex
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-Base64ToZ85 converts Base64 to Z85' {
            $testBase64 = 'SGVsbG8gV29ybGQ='
            $result = $testBase64 | ConvertFrom-Base64ToZ85
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Z85ToBase64 converts Z85 to Base64' {
            $testZ85 = 'nm=QNzY&b0A'
            $result = $testZ85 | ConvertFrom-Z85ToBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Base64 to Z85 and back roundtrip' {
            $original = 'SGVsbG8gV29ybGQ='
            $z85 = $original | ConvertFrom-Base64ToZ85
            $base64 = $z85 | ConvertFrom-Z85ToBase64
            $base64 | Should -Be $original
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToZ85
            $result | Should -Be ''
        }
    }
}

