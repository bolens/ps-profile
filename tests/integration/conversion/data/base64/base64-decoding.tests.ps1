

<#
.SYNOPSIS
    Integration tests for Base64 decoding utilities.

.DESCRIPTION
    This test suite validates Base64 decoding functions.

.NOTES
    Tests cover decoding functionality and edge cases.
#>

Describe 'Base64 Decoding Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Base64 decoding utilities' {
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

        It 'ConvertFrom-Base64 handles invalid base64 gracefully' {
            $invalidBase64 = 'invalid base64!'
            { ConvertFrom-Base64 -InputObject $invalidBase64 2>$null } | Should -Not -Throw
        }
    }
}

