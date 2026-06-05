

<#
.SYNOPSIS
    Integration tests for Base91 encoding conversion utilities.

.DESCRIPTION
    This test suite validates Base91 encoding conversion functions including conversions to/from ASCII, Hex, and Base64.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Base91 Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-ConversionIntegrationForTestFile -ProfileDir $script:ProfileDir
    }

    Context 'Base91 Encoding Conversions' {
        It 'ConvertFrom-AsciiToBase91 converts ASCII to Base91' {
            $testString = 'Hello World'
            $result = $testString | ConvertFrom-AsciiToBase91
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base91ToAscii converts Base91 to ASCII' {
            $testBase91 = '>OwJh>Io0Tv!8PE'
            $result = $testBase91 | ConvertFrom-Base91ToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ASCII to Base91 and back roundtrip' {
            $original = 'Hello World'
            $base91 = $original | ConvertFrom-AsciiToBase91
            $decoded = $base91 | ConvertFrom-Base91ToAscii
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-HexToBase91 converts Hex to Base91' {
            $testHex = '48656C6C6F'
            $result = $testHex | ConvertFrom-HexToBase91
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base91ToHex converts Base91 to Hex' {
            $testBase91 = '>OwJh>Io0Tv!8PE'
            $result = $testBase91 | ConvertFrom-Base91ToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Hex to Base91 and back roundtrip' {
            $original = '48656C6C6F'
            $base91 = $original | ConvertFrom-HexToBase91
            $decoded = $base91 | ConvertFrom-Base91ToHex
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-Base64ToBase91 converts Base64 to Base91' {
            $testBase64 = 'SGVsbG8gV29ybGQ='
            $result = $testBase64 | ConvertFrom-Base64ToBase91
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base91ToBase64 converts Base91 to Base64' {
            $testBase91 = '>OwJh>Io0Tv!8PE'
            $result = $testBase91 | ConvertFrom-Base91ToBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Base64 to Base91 and back roundtrip' {
            $original = 'SGVsbG8gV29ybGQ='
            $base91 = $original | ConvertFrom-Base64ToBase91
            $base64 = $base91 | ConvertFrom-Base91ToBase64
            $base64 | Should -Be $original
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToBase91
            $result | Should -Be ''
        }
    }
}

