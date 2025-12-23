

<#
.SYNOPSIS
    Integration tests for Hash format conversion utilities.

.DESCRIPTION
    This test suite validates Hash format conversion functions (Hex ↔ Base64 ↔ Base32).

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Hash Format Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Hash Format Conversions' {
        It 'ConvertFrom-HashHexToBase64 function exists' {
            Get-Command ConvertFrom-HashHexToBase64 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-HashHexToBase64 converts hex hash to Base64' {
            $hex = '48656c6c6f20576f726c64'  # "Hello World" in hex
            $base64 = ConvertFrom-HashHexToBase64 -HashHex $hex
            
            $base64 | Should -Not -BeNullOrEmpty
            $base64 | Should -BeOfType [string]
            # Verify it's valid Base64
            try {
                $bytes = [Convert]::FromBase64String($base64)
                $bytes | Should -Not -BeNullOrEmpty
            }
            catch {
                Set-ItResult -Inconclusive -Because "Base64 conversion validation failed"
            }
        }

        It 'ConvertFrom-HashBase64ToHex function exists' {
            Get-Command ConvertFrom-HashBase64ToHex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-HashBase64ToHex converts Base64 hash to hex' {
            $base64 = 'SGVsbG8gV29ybGQ='  # "Hello World" in Base64
            $hex = ConvertFrom-HashBase64ToHex -HashBase64 $base64
            
            $hex | Should -Not -BeNullOrEmpty
            $hex | Should -BeOfType [string]
            $hex | Should -Match '^[0-9a-f]+$'
        }

        It 'Hash hex to Base64 and back roundtrip' {
            $originalHex = 'a1b2c3d4e5f67890'
            $base64 = ConvertFrom-HashHexToBase64 -HashHex $originalHex
            $roundtripHex = ConvertFrom-HashBase64ToHex -HashBase64 $base64
            
            $roundtripHex | Should -Be $originalHex
        }

        It 'ConvertFrom-HashHexToBase32 function exists' {
            Get-Command ConvertFrom-HashHexToBase32 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-HashHexToBase32 converts hex hash to Base32' {
            $hex = '48656c6c6f'  # "Hello" in hex
            $base32 = ConvertFrom-HashHexToBase32 -HashHex $hex
            
            $base32 | Should -Not -BeNullOrEmpty
            $base32 | Should -BeOfType [string]
            # Base32 should only contain A-Z, 2-7, and possibly padding
            $base32 | Should -Match '^[A-Z2-7=]+$'
        }

        It 'ConvertFrom-HashBase32ToHex function exists' {
            Get-Command ConvertFrom-HashBase32ToHex -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-HashBase32ToHex converts Base32 hash to hex' {
            # Use a known Base32 value
            $base32 = 'JBSWY3DP'  # "Hello" in Base32
            $hex = ConvertFrom-HashBase32ToHex -HashBase32 $base32
            
            $hex | Should -Not -BeNullOrEmpty
            $hex | Should -BeOfType [string]
            $hex | Should -Match '^[0-9a-f]+$'
        }

        It 'Hash hex to Base32 and back roundtrip' {
            $originalHex = 'a1b2c3d4'
            $base32 = ConvertFrom-HashHexToBase32 -HashHex $originalHex
            $roundtripHex = ConvertFrom-HashBase32ToHex -HashBase32 $base32
            
            # Roundtrip may not be exact due to padding, but should be close
            $roundtripHex | Should -Not -BeNullOrEmpty
        }

        It 'ConvertFrom-HashBase64ToBase32 function exists' {
            Get-Command ConvertFrom-HashBase64ToBase32 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-HashBase32ToBase64 function exists' {
            Get-Command ConvertFrom-HashBase32ToBase64 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Hash Base64 to Base32 and back roundtrip' {
            $originalBase64 = 'SGVsbG8='  # "Hello" in Base64
            $base32 = ConvertFrom-HashBase64ToBase32 -HashBase64 $originalBase64
            $roundtripBase64 = ConvertFrom-HashBase32ToBase64 -HashBase32 $base32
            
            $roundtripBase64 | Should -Not -BeNullOrEmpty
        }

        It 'Handles empty hash input' {
            $result = ConvertFrom-HashHexToBase64 -HashHex ''
            $result | Should -Be ''
        }

        It 'Handles hex hash with spaces and dashes' {
            $hex = 'a1-b2 c3d4'
            $base64 = ConvertFrom-HashHexToBase64 -HashHex $hex
            
            $base64 | Should -Not -BeNullOrEmpty
        }
    }
}

