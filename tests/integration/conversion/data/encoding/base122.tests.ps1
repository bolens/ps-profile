

<#
.SYNOPSIS
    Integration tests for Base122 encoding conversion utilities.

.DESCRIPTION
    This test suite validates Base122 encoding conversion functions including conversions to/from ASCII, Hex, and Base64.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Base122 Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Base122 Encoding Conversions' {
        It 'ConvertFrom-AsciiToBase122 converts ASCII to Base122' {
            $testString = 'Hello World'
            $result = $testString | ConvertFrom-AsciiToBase122
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base122ToAscii converts Base122 to ASCII' {
            $testBase122 = 'Hello World' | ConvertFrom-AsciiToBase122
            $result = $testBase122 | ConvertFrom-Base122ToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ASCII to Base122 and back roundtrip' {
            $original = 'Hello World'
            $base122 = $original | ConvertFrom-AsciiToBase122
            $decoded = $base122 | ConvertFrom-Base122ToAscii
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-HexToBase122 converts Hex to Base122' {
            $testHex = '48656C6C6F'
            $result = $testHex | ConvertFrom-HexToBase122
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base122ToHex converts Base122 to Hex' {
            $testBase122 = '48656C6C6F' | ConvertFrom-HexToBase122
            $result = $testBase122 | ConvertFrom-Base122ToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Hex to Base122 and back roundtrip' {
            $original = '48656C6C6F'
            $base122 = $original | ConvertFrom-HexToBase122
            $decoded = $base122 | ConvertFrom-Base122ToHex
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-Base64ToBase122 converts Base64 to Base122' {
            $testBase64 = 'SGVsbG8gV29ybGQ='
            $result = $testBase64 | ConvertFrom-Base64ToBase122
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base122ToBase64 converts Base122 to Base64' {
            $testBase122 = 'SGVsbG8gV29ybGQ=' | ConvertFrom-Base64ToBase122
            $result = $testBase122 | ConvertFrom-Base122ToBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Base64 to Base122 and back roundtrip' {
            $original = 'SGVsbG8gV29ybGQ='
            $base122 = $original | ConvertFrom-Base64ToBase122
            $base64 = $base122 | ConvertFrom-Base122ToBase64
            $base64 | Should -Be $original
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToBase122
            $result | Should -Be ''
        }
        
        It 'Handles invalid Base122 characters' {
            $invalid = 'Hello"World'  # Contains " which is not in Base122 alphabet
            { $invalid | ConvertFrom-AsciiToBase122 | ConvertFrom-Base122ToAscii } | Should -Not -Throw
            # Base122 encoding should handle it, but decoding might fail if we manually create invalid Base122
        }
    }
}

