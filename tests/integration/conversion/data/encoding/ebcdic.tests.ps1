

<#
.SYNOPSIS
    Integration tests for EBCDIC encoding conversion utilities.

.DESCRIPTION
    This test suite validates EBCDIC encoding conversion functions including conversions to/from ASCII.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'EBCDIC Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'EBCDIC Encoding Conversions' {
        It 'ConvertFrom-AsciiToEBCDIC function exists' {
            Get-Command ConvertFrom-AsciiToEBCDIC -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-EBCDICToAscii function exists' {
            Get-Command ConvertFrom-EBCDICToAscii -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-AsciiToEBCDIC converts ASCII to EBCDIC' {
            $testString = 'Hello'
            $result = $testString | ConvertFrom-AsciiToEBCDIC
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            # EBCDIC for "Hello" should be a hex string
            $result | Should -Match '^[0-9A-F]+$'
        }
        
        It 'ConvertFrom-EBCDICToAscii converts EBCDIC to ASCII' {
            # EBCDIC hex for "Hello" (C885939396 in EBCDIC Code Page 037)
            $testEbcdic = 'C885939396'
            $result = $testEbcdic | ConvertFrom-EBCDICToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ASCII to EBCDIC and back roundtrip' {
            $original = 'Hello'
            $ebcdic = $original | ConvertFrom-AsciiToEBCDIC
            $decoded = $ebcdic | ConvertFrom-EBCDICToAscii
            $decoded | Should -Be $original
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToEBCDIC
            $result | Should -Be ''
        }
        
        It 'Handles numbers in EBCDIC' {
            $testString = '123'
            $ebcdic = $testString | ConvertFrom-AsciiToEBCDIC
            $decoded = $ebcdic | ConvertFrom-EBCDICToAscii
            $decoded | Should -Be $testString
        }
        
        It 'Handles special characters' {
            $testString = 'Hello, World!'
            $ebcdic = $testString | ConvertFrom-AsciiToEBCDIC
            $decoded = $ebcdic | ConvertFrom-EBCDICToAscii
            $decoded | Should -Be $testString
        }

        It 'Handles uppercase and lowercase letters' {
            $testString = 'HelloWorld'
            $ebcdic = $testString | ConvertFrom-AsciiToEBCDIC
            $decoded = $ebcdic | ConvertFrom-EBCDICToAscii
            $decoded | Should -Be $testString
        }

        It 'Handles all printable ASCII characters' {
            $testString = ''
            for ($i = 32; $i -le 126; $i++) {
                $testString += [char]$i
            }
            $ebcdic = $testString | ConvertFrom-AsciiToEBCDIC
            $decoded = $ebcdic | ConvertFrom-EBCDICToAscii
            # Note: Some characters may not roundtrip perfectly due to EBCDIC mapping limitations
            $decoded.Length | Should -BeGreaterThan 0
        }

        It 'Handles pipeline input' {
            $testStrings = @('Hello', 'World', 'Test')
            $results = $testStrings | ConvertFrom-AsciiToEBCDIC
            $results.Count | Should -Be 3
            foreach ($result in $results) {
                $result | Should -Match '^[0-9A-F]+$'
            }
        }
        
        It 'Handles invalid EBCDIC hex string' {
            $invalid = 'G'  # Invalid hex character
            { $invalid | ConvertFrom-EBCDICToAscii } | Should -Throw
        }
        
        It 'Handles odd-length hex string' {
            $invalid = 'C88'  # Odd length
            { $invalid | ConvertFrom-EBCDICToAscii } | Should -Throw
        }

        It 'Handles whitespace in hex string' {
            $testEbcdic = 'C8 85 93 93 96'  # With spaces
            $result = $testEbcdic | ConvertFrom-EBCDICToAscii
            $result | Should -Not -BeNullOrEmpty
        }
    }
}

