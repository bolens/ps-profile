

<#
.SYNOPSIS
    Integration tests for Base64 roundtrip conversions.

.DESCRIPTION
    This test suite validates Base64 encoding and decoding roundtrip functionality.

.NOTES
    Tests cover roundtrip scenarios and edge cases.
#>

Describe 'Base64 Roundtrip Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Base64 roundtrip utilities' {
        It 'ConvertTo-Base64 and ConvertFrom-Base64 roundtrip' {
            $original = 'Test string with unicode: ñáéíóú'
            $base64 = ConvertTo-Base64 -InputObject $original
            $decoded = ConvertFrom-Base64 -InputObject $base64
            $decoded | Should -Be $original
        }
    }
}

