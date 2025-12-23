

<#
.SYNOPSIS
    Integration tests for Morse Code encoding conversion utilities.

.DESCRIPTION
    This test suite validates Morse Code conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Morse Code Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Morse Code Conversions' {
        It 'ConvertFrom-AsciiToMorse converts ASCII to Morse Code' {
            $testString = 'HELLO WORLD'
            $result = $testString | ConvertFrom-AsciiToMorse
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Match '\.|-'
        }
        
        It 'ConvertFrom-MorseToAscii converts Morse Code to ASCII' {
            $testMorse = '.... . .-.. .-.. ---  .-- --- .-. .-.. -..'
            $result = $testMorse | ConvertFrom-MorseToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Be 'HELLO WORLD'
        }
        
        It 'ASCII to Morse Code and back roundtrip' {
            $original = 'HELLO WORLD'
            $morse = $original | ConvertFrom-AsciiToMorse
            $decoded = $morse | ConvertFrom-MorseToAscii
            $decoded | Should -Be $original
        }
        
        It 'SOS in Morse Code' {
            $sos = 'SOS'
            $morse = $sos | ConvertFrom-AsciiToMorse
            $morse | Should -Be '... --- ...'
            $decoded = $morse | ConvertFrom-MorseToAscii
            $decoded | Should -Be 'SOS'
        }
        
        It 'Handles numbers in Morse Code' {
            $testString = '123'
            $result = $testString | ConvertFrom-AsciiToMorse
            $result | Should -Not -BeNullOrEmpty
            $decoded = $result | ConvertFrom-MorseToAscii
            $decoded | Should -Be '123'
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToMorse
            $result | Should -Be ''
        }
        
        It 'Handles words separated by spaces' {
            $testString = 'HELLO WORLD'
            $result = $testString | ConvertFrom-AsciiToMorse
            # Should have double space between words
            $result | Should -Match '\s{2,}'
        }
    }
}

