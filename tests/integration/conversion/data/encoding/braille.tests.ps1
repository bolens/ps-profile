

<#
.SYNOPSIS
    Integration tests for Braille encoding conversion utilities.

.DESCRIPTION
    This test suite validates Braille encoding conversion functions including conversions to/from ASCII.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Braille Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Braille Encoding Conversions' {
        It 'ConvertFrom-AsciiToBraille function exists' {
            Get-Command ConvertFrom-AsciiToBraille -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-BrailleToAscii function exists' {
            Get-Command ConvertFrom-BrailleToAscii -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-AsciiToBraille converts ASCII to Braille' {
            $testString = 'HELLO'
            $result = $testString | ConvertFrom-AsciiToBraille
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            # Braille should contain Unicode Braille characters
            $result.Length | Should -BeGreaterThan 0
        }
        
        It 'ConvertFrom-BrailleToAscii converts Braille to ASCII' {
            $testBraille = 'HELLO' | ConvertFrom-AsciiToBraille
            $result = $testBraille | ConvertFrom-BrailleToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ASCII to Braille and back roundtrip' {
            $original = 'HELLO'
            $braille = $original | ConvertFrom-AsciiToBraille
            $decoded = $braille | ConvertFrom-BrailleToAscii
            $decoded | Should -Be $original
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToBraille
            $result | Should -Be ''
        }
        
        It 'Handles numbers in Braille' {
            $testString = '123'
            $braille = $testString | ConvertFrom-AsciiToBraille
            $decoded = $braille | ConvertFrom-BrailleToAscii
            $decoded | Should -Be $testString
        }
        
        It 'Handles spaces in Braille' {
            $testString = 'HELLO WORLD'
            $braille = $testString | ConvertFrom-AsciiToBraille
            $decoded = $braille | ConvertFrom-BrailleToAscii
            $decoded | Should -Be $testString
        }
        
        It 'Handles punctuation in Braille' {
            $testString = 'HELLO, WORLD!'
            $braille = $testString | ConvertFrom-AsciiToBraille
            $decoded = $braille | ConvertFrom-BrailleToAscii
            $decoded | Should -Be $testString
        }
        
        It 'Handles lowercase letters (converts to uppercase)' {
            $testString = 'hello'
            $braille = $testString | ConvertFrom-AsciiToBraille
            $decoded = $braille | ConvertFrom-BrailleToAscii
            # Braille encoding converts to uppercase
            $decoded | Should -Be 'HELLO'
        }
        
        It 'Handles mixed case and numbers' {
            $testString = 'Hello123'
            $braille = $testString | ConvertFrom-AsciiToBraille
            $decoded = $braille | ConvertFrom-BrailleToAscii
            # Should handle numbers correctly
            $decoded | Should -Match '123'
        }

        It 'Handles all uppercase letters A-Z' {
            $testString = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
            $braille = $testString | ConvertFrom-AsciiToBraille
            $decoded = $braille | ConvertFrom-BrailleToAscii
            $decoded | Should -Be $testString
        }

        It 'Handles all digits 0-9' {
            $testString = '0123456789'
            $braille = $testString | ConvertFrom-AsciiToBraille
            $decoded = $braille | ConvertFrom-BrailleToAscii
            $decoded | Should -Be $testString
        }

        It 'Handles multiple spaces' {
            $testString = 'HELLO  WORLD'
            $braille = $testString | ConvertFrom-AsciiToBraille
            $decoded = $braille | ConvertFrom-BrailleToAscii
            $decoded | Should -Be $testString
        }

        It 'Handles pipeline input' {
            $testStrings = @('HELLO', 'WORLD', 'TEST')
            $results = $testStrings | ConvertFrom-AsciiToBraille
            $results.Count | Should -Be 3
            foreach ($result in $results) {
                $result | Should -Not -BeNullOrEmpty
            }
        }

        It 'Handles unknown characters gracefully' {
            $testString = 'HELLO@#$%WORLD'  # Contains unsupported characters
            $braille = $testString | ConvertFrom-AsciiToBraille
            $decoded = $braille | ConvertFrom-BrailleToAscii
            # Should handle gracefully, converting unknown chars to spaces
            $decoded | Should -Not -BeNullOrEmpty
        }
    }
}

