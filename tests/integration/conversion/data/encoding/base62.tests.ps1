

<#
.SYNOPSIS
    Integration tests for Base62 encoding conversion utilities.

.DESCRIPTION
    This test suite validates Base62 encoding conversion functions including conversions to/from ASCII, Hex, and Base64.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Base62 Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Base62 Encoding Conversions' {
        It 'ConvertFrom-AsciiToBase62 converts ASCII to Base62' {
            $testString = 'Hello World'
            $result = $testString | ConvertFrom-AsciiToBase62
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base62ToAscii converts Base62 to ASCII' {
            $testBase62 = '73W9kKxE'
            $result = $testBase62 | ConvertFrom-Base62ToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ASCII to Base62 and back roundtrip' {
            $original = 'Hello World'
            $base62 = $original | ConvertFrom-AsciiToBase62
            $decoded = $base62 | ConvertFrom-Base62ToAscii
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-HexToBase62 converts Hex to Base62' {
            $testHex = '48656C6C6F'
            $result = $testHex | ConvertFrom-HexToBase62
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base62ToHex converts Base62 to Hex' {
            $testBase62 = '73W9kKxE'
            $result = $testBase62 | ConvertFrom-Base62ToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Hex to Base62 and back roundtrip' {
            $original = '48656C6C6F'
            $base62 = $original | ConvertFrom-HexToBase62
            $decoded = $base62 | ConvertFrom-Base62ToHex
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-Base64ToBase62 converts Base64 to Base62' {
            $testBase64 = 'SGVsbG8gV29ybGQ='
            $result = $testBase64 | ConvertFrom-Base64ToBase62
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base62ToBase64 converts Base62 to Base64' {
            $testBase62 = '73W9kKxE'
            $result = $testBase62 | ConvertFrom-Base62ToBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Base64 to Base62 and back roundtrip' {
            $original = 'SGVsbG8gV29ybGQ='
            $base62 = $original | ConvertFrom-Base64ToBase62
            $base64 = $base62 | ConvertFrom-Base62ToBase64
            $base64 | Should -Be $original
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToBase62
            $result | Should -Be ''
        }
    }
}

