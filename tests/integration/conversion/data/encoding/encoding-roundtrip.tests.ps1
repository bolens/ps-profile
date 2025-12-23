

<#
.SYNOPSIS
    Integration tests for complex encoding roundtrip conversions.

.DESCRIPTION
    This test suite validates complex roundtrip conversions including Base32, URL encoding,
    and multi-format chain conversions.

.NOTES
    Tests cover complex roundtrip scenarios and cross-format conversions.
#>

Describe 'Encoding Roundtrip and Complex Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Complex roundtrip conversions' {
        It 'Complex roundtrip: ASCII → Hex → Binary → ModHex → Binary → Hex → ASCII' {
            $original = 'Test'
            $hex = $original | ConvertFrom-AsciiToHex
            $binary = $hex | ConvertFrom-HexToBinary
            $modhex = $binary | ConvertFrom-BinaryToModHex
            $binary2 = $modhex | ConvertFrom-ModHexToBinary
            $hex2 = $binary2 | ConvertFrom-BinaryToHex
            $result = $hex2 | ConvertFrom-HexToAscii
            $result | Should -Be $original
        }
    }

    Context 'ASCII to Base32 conversions' {
        It 'Converts ASCII text to Base32' {
            $result = 'Hello' | ConvertFrom-AsciiToBase32
            $result | Should -Not -BeNullOrEmpty
            # Base32 should only contain A-Z, 2-7, and padding =
            $result -match '^[A-Z2-7=]+$' | Should -Be $true
        }

        It 'Converts empty string to empty Base32' {
            $result = '' | ConvertFrom-AsciiToBase32
            $result | Should -Be ''
        }

        It 'Converts single character to Base32' {
            $result = 'A' | ConvertFrom-AsciiToBase32
            $result | Should -Not -BeNullOrEmpty
        }

        It 'Converts text with spaces to Base32' {
            $result = 'Hello World' | ConvertFrom-AsciiToBase32
            $result | Should -Not -BeNullOrEmpty
        }
    }

    Context 'Base32 to ASCII conversions' {
        It 'Converts Base32 to ASCII text' {
            $ascii = 'Hello'
            $base32 = $ascii | ConvertFrom-AsciiToBase32
            $result = $base32 | ConvertFrom-Base32ToAscii
            $result | Should -Be $ascii
        }

        It 'Converts Base32 with padding to ASCII' {
            $ascii = 'Hi'
            $base32 = $ascii | ConvertFrom-AsciiToBase32
            $result = $base32 | ConvertFrom-Base32ToAscii
            $result | Should -Be $ascii
        }

        It 'Converts empty Base32 to empty string' {
            $result = '' | ConvertFrom-Base32ToAscii
            $result | Should -Be ''
        }

        It 'Throws error for invalid Base32 characters' {
            { 'Hello!' | ConvertFrom-Base32ToAscii } | Should -Throw
        }
    }

    Context 'Base32 roundtrip conversions' {
        It 'ASCII → Base32 → ASCII roundtrip' {
            $original = 'Hello World!'
            $base32 = $original | ConvertFrom-AsciiToBase32
            $result = $base32 | ConvertFrom-Base32ToAscii
            $result | Should -Be $original
        }

        It 'Hex → Base32 → Hex roundtrip' {
            $original = '48656C6C6F'
            $base32 = $original | ConvertFrom-HexToBase32
            $result = $base32 | ConvertFrom-Base32ToHex
            $result | Should -Be $original
        }

        It 'Binary → Base32 → Binary roundtrip' {
            $original = '01001000 01101001'
            $base32 = $original | ConvertFrom-BinaryToBase32
            $result = $base32 | ConvertFrom-Base32ToBinary
            $result | Should -Be $original
        }
    }

    Context 'Base32 to other formats' {
        It 'Converts Base32 to Hex' {
            $ascii = 'Hello'
            $base32 = $ascii | ConvertFrom-AsciiToBase32
            $hex = $base32 | ConvertFrom-Base32ToHex
            $result = $hex | ConvertFrom-HexToAscii
            $result | Should -Be $ascii
        }

        It 'Converts Base32 to Binary' {
            $ascii = 'Hi'
            $base32 = $ascii | ConvertFrom-AsciiToBase32
            $binary = $base32 | ConvertFrom-Base32ToBinary
            $result = $binary | ConvertFrom-BinaryToAscii
            $result | Should -Be $ascii
        }

        It 'Converts Base32 to ModHex' {
            $ascii = 'Test'
            $base32 = $ascii | ConvertFrom-AsciiToBase32
            $modhex = $base32 | ConvertFrom-Base32ToModHex
            $result = $modhex | ConvertFrom-ModHexToAscii
            $result | Should -Be $ascii
        }
    }

    Context 'Base32 aliases' {
        It 'ascii-to-base32 alias works' {
            $result = 'Hello' | ascii-to-base32
            $result | Should -Not -BeNullOrEmpty
        }

        It 'base32-to-ascii alias works' {
            $ascii = 'Hello'
            $base32 = $ascii | ascii-to-base32
            $result = $base32 | base32-to-ascii
            $result | Should -Be $ascii
        }
    }

    Context 'ASCII to URL encoding conversions' {
        It 'Converts ASCII text to URL encoding' {
            $result = 'Hello World' | ConvertFrom-AsciiToUrl
            $result | Should -Be 'Hello%20World'
        }

        It 'Converts special characters to URL encoding' {
            $result = 'test@example.com' | ConvertFrom-AsciiToUrl
            $result | Should -Be 'test%40example.com'
        }

        It 'Converts empty string to empty URL encoding' {
            $result = '' | ConvertFrom-AsciiToUrl
            $result | Should -Be ''
        }

        It 'Leaves unreserved characters unchanged' {
            $result = 'Hello-World_Test.123~' | ConvertFrom-AsciiToUrl
            $result | Should -Be 'Hello-World_Test.123~'
        }

        It 'Encodes space as %20' {
            $result = 'a b' | ConvertFrom-AsciiToUrl
            $result | Should -Be 'a%20b'
        }

        It 'Encodes multiple special characters' {
            $result = '!@#$%^&*()' | ConvertFrom-AsciiToUrl
            $result | Should -Not -BeNullOrEmpty
            # Verify roundtrip
            $decoded = $result | ConvertFrom-UrlToAscii
            $decoded | Should -Be '!@#$%^&*()'
        }
    }

    Context 'URL encoding to ASCII conversions' {
        It 'Converts URL encoding to ASCII text' {
            $result = 'Hello%20World' | ConvertFrom-UrlToAscii
            $result | Should -Be 'Hello World'
        }

        It 'Converts URL encoding with special characters' {
            $result = 'test%40example.com' | ConvertFrom-UrlToAscii
            $result | Should -Be 'test@example.com'
        }

        It 'Converts empty URL encoding to empty string' {
            $result = '' | ConvertFrom-UrlToAscii
            $result | Should -Be ''
        }

        It 'Handles lowercase hex in URL encoding' {
            $result = 'Hello%20world' | ConvertFrom-UrlToAscii
            $result | Should -Be 'Hello world'
        }

        It 'Handles uppercase hex in URL encoding' {
            $result = 'Hello%20WORLD' | ConvertFrom-UrlToAscii
            $result | Should -Be 'Hello WORLD'
        }

        It 'Handles multiple percent-encoded sequences' {
            $result = '%48%65%6C%6C%6F' | ConvertFrom-UrlToAscii
            $result | Should -Be 'Hello'
        }
    }

    Context 'URL encoding roundtrip conversions' {
        It 'ASCII → URL → ASCII roundtrip' {
            $original = 'Hello World!'
            $url = $original | ConvertFrom-AsciiToUrl
            $result = $url | ConvertFrom-UrlToAscii
            $result | Should -Be $original
        }

        It 'ASCII → URL → ASCII roundtrip with special characters' {
            $original = 'test@example.com/path?query=value&other=123'
            $url = $original | ConvertFrom-AsciiToUrl
            $result = $url | ConvertFrom-UrlToAscii
            $result | Should -Be $original
        }

        It 'Hex → URL → Hex roundtrip' {
            $original = '48656C6C6F'
            $url = $original | ConvertFrom-HexToUrl
            $result = $url | ConvertFrom-UrlToHex
            $result | Should -Be $original
        }

        It 'Binary → URL → Binary roundtrip' {
            $original = '01001000 01101001'
            $url = $original | ConvertFrom-BinaryToUrl
            $result = $url | ConvertFrom-UrlToBinary
            $result | Should -Be $original
        }
    }

    Context 'URL encoding to other formats' {
        It 'Converts URL encoding to Hex' {
            $ascii = 'Hello'
            $url = $ascii | ConvertFrom-AsciiToUrl
            $hex = $url | ConvertFrom-UrlToHex
            $result = $hex | ConvertFrom-HexToAscii
            $result | Should -Be $ascii
        }

        It 'Converts URL encoding to Binary' {
            $ascii = 'Hi'
            $url = $ascii | ConvertFrom-AsciiToUrl
            $binary = $url | ConvertFrom-UrlToBinary
            $result = $binary | ConvertFrom-BinaryToAscii
            $result | Should -Be $ascii
        }

        It 'Converts URL encoding to Base32' {
            $ascii = 'Test'
            $url = $ascii | ConvertFrom-AsciiToUrl
            $base32 = $url | ConvertFrom-UrlToBase32
            $result = $base32 | ConvertFrom-Base32ToAscii
            $result | Should -Be $ascii
        }

        It 'Converts URL encoding to ModHex' {
            $ascii = 'Hello'
            $url = $ascii | ConvertFrom-AsciiToUrl
            $modhex = $url | ConvertFrom-UrlToModHex
            $result = $modhex | ConvertFrom-ModHexToAscii
            $result | Should -Be $ascii
        }
    }

    Context 'URL encoding aliases' {
        It 'ascii-to-url alias works' {
            $result = 'Hello World' | ascii-to-url
            $result | Should -Be 'Hello%20World'
        }

        It 'url-to-ascii alias works' {
            $result = 'Hello%20World' | url-to-ascii
            $result | Should -Be 'Hello World'
        }

        It 'url-encode alias works' {
            $result = 'test@example.com' | url-encode
            $result | Should -Be 'test%40example.com'
        }

        It 'url-decode alias works' {
            $result = 'test%40example.com' | url-decode
            $result | Should -Be 'test@example.com'
        }
    }

    Context 'Complex roundtrips with Base32 and URL encoding' {
        It 'ASCII → Base32 → URL → Base32 → ASCII roundtrip' {
            $original = 'Test String'
            $base32 = $original | ConvertFrom-AsciiToBase32
            $url = $base32 | ConvertFrom-Base32ToUrl
            $base32_2 = $url | ConvertFrom-UrlToBase32
            $result = $base32_2 | ConvertFrom-Base32ToAscii
            $result | Should -Be $original
        }

        It 'ASCII → URL → Base32 → URL → ASCII roundtrip' {
            $original = 'Hello World'
            $url = $original | ConvertFrom-AsciiToUrl
            $base32 = $url | ConvertFrom-UrlToBase32
            $url_2 = $base32 | ConvertFrom-Base32ToUrl
            $result = $url_2 | ConvertFrom-UrlToAscii
            $result | Should -Be $original
        }
    }
}

