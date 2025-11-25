. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

<#
.SYNOPSIS
    Integration tests for Base64 encoding/decoding utilities.

.DESCRIPTION
    This test suite validates Base64 encoding and decoding functions.

.NOTES
    Tests cover encoding, decoding, roundtrips, and edge cases.
#>

Describe 'Base64 Conversion Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        . (Join-Path $script:ProfileDir '00-bootstrap.ps1')
        . (Join-Path $script:ProfileDir '02-files.ps1')
        Ensure-FileConversion-Data
    }

    Context 'Base64 conversion utilities' {
        It 'ConvertTo-Base64 encodes string to base64' {
            $text = 'Hello World'
            $base64 = ConvertTo-Base64 -InputObject $text
            $base64 | Should -Not -BeNullOrEmpty
            $base64 | Should -Be 'SGVsbG8gV29ybGQ='
        }

        It 'ConvertTo-Base64 handles empty string' {
            $text = ''
            $base64 = ConvertTo-Base64 -InputObject $text
            $base64 | Should -Be ''
        }

        It 'ConvertTo-Base64 handles special characters' {
            $text = 'Test with special chars: !@#$%^&*()'
            $base64 = ConvertTo-Base64 -InputObject $text
            $base64 | Should -Not -BeNullOrEmpty
            # Verify it's valid base64 by decoding back
            $decoded = ConvertFrom-Base64 -InputObject $base64
            $decoded | Should -Be $text
        }

        It 'ConvertFrom-Base64 decodes base64 to string' {
            $base64 = 'SGVsbG8gV29ybGQ='
            $text = ConvertFrom-Base64 -InputObject $base64
            $text | Should -Be 'Hello World'
        }

        It 'ConvertFrom-Base64 handles empty base64 string' {
            $base64 = ''
            $text = ConvertFrom-Base64 -InputObject $base64
            $text | Should -Be ''
        }

        It 'ConvertTo-Base64 and ConvertFrom-Base64 roundtrip' {
            $original = 'Test string with unicode: ñáéíóú'
            $base64 = ConvertTo-Base64 -InputObject $original
            $decoded = ConvertFrom-Base64 -InputObject $base64
            $decoded | Should -Be $original
        }

        It 'ConvertFrom-Base64 handles invalid base64 gracefully' {
            $invalidBase64 = 'invalid base64!'
            { ConvertFrom-Base64 -InputObject $invalidBase64 2>$null } | Should -Not -Throw
        }
    }
}

