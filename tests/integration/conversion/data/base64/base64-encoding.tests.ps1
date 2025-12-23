

<#
.SYNOPSIS
    Integration tests for Base64 encoding utilities.

.DESCRIPTION
    This test suite validates Base64 encoding functions.

.NOTES
    Tests cover encoding functionality and edge cases.
#>

Describe 'Base64 Encoding Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Base64 encoding utilities' {
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
    }
}

