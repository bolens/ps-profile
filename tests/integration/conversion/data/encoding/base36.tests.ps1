

<#
.SYNOPSIS
    Integration tests for Base36 encoding conversion utilities.

.DESCRIPTION
    This test suite validates Base36 encoding conversion functions including conversions to/from ASCII, Hex, and Base64.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Base36 Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Base36 Encoding Conversions' {
        It 'ConvertFrom-AsciiToBase36 converts ASCII to Base36' {
            $testString = 'Hello World'
            $result = $testString | ConvertFrom-AsciiToBase36
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base36ToAscii converts Base36 to ASCII' {
            $testBase36 = '91IXPRL3'
            $result = $testBase36 | ConvertFrom-Base36ToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ASCII to Base36 and back roundtrip' {
            $original = 'Hello World'
            $base36 = $original | ConvertFrom-AsciiToBase36
            $decoded = $base36 | ConvertFrom-Base36ToAscii
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-HexToBase36 converts Hex to Base36' {
            $testHex = '48656C6C6F'
            $result = $testHex | ConvertFrom-HexToBase36
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base36ToHex converts Base36 to Hex' {
            $testBase36 = '91IXPRL3'
            $result = $testBase36 | ConvertFrom-Base36ToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Hex to Base36 and back roundtrip' {
            $original = '48656C6C6F'
            $base36 = $original | ConvertFrom-HexToBase36
            $decoded = $base36 | ConvertFrom-Base36ToHex
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-Base64ToBase36 converts Base64 to Base36' {
            $testBase64 = 'SGVsbG8gV29ybGQ='
            $result = $testBase64 | ConvertFrom-Base64ToBase36
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base36ToBase64 converts Base36 to Base64' {
            $testBase36 = '91IXPRL3'
            $result = $testBase36 | ConvertFrom-Base36ToBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Base64 to Base36 and back roundtrip' {
            $original = 'SGVsbG8gV29ybGQ='
            $base36 = $original | ConvertFrom-Base64ToBase36
            $base64 = $base36 | ConvertFrom-Base36ToBase64
            $base64 | Should -Be $original
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToBase36
            $result | Should -Be ''
        }
        
        It 'Handles invalid Base36 characters' {
            $invalid = 'Hello World!'  # Contains '!' which is not in Base36 alphabet
            { $invalid | ConvertFrom-Base36ToAscii } | Should -Throw
        }
    }
}

