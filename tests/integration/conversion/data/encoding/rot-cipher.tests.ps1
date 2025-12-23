

<#
.SYNOPSIS
    Integration tests for ROT13 and ROT47 cipher encoding conversion utilities.

.DESCRIPTION
    This test suite validates ROT13 and ROT47 cipher conversion functions.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
    ROT ciphers are self-inverse (applying twice returns the original).
#>

Describe 'ROT Cipher Encoding Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'ROT13 Cipher Conversions' {
        It 'ConvertFrom-AsciiToRot13 converts ASCII to ROT13' {
            $testString = 'Hello World'
            $result = $testString | ConvertFrom-AsciiToRot13
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Be 'Uryyb Jbeyq'
        }
        
        It 'ConvertFrom-Rot13ToAscii converts ROT13 to ASCII' {
            $testRot13 = 'Uryyb Jbeyq'
            $result = $testRot13 | ConvertFrom-Rot13ToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Be 'Hello World'
        }
        
        It 'ASCII to ROT13 and back roundtrip' {
            $original = 'Hello World'
            $rot13 = $original | ConvertFrom-AsciiToRot13
            $decoded = $rot13 | ConvertFrom-Rot13ToAscii
            $decoded | Should -Be $original
        }
        
        It 'ROT13 is self-inverse (double application returns original)' {
            $original = 'Hello World'
            $rot13Once = $original | ConvertFrom-AsciiToRot13
            $rot13Twice = $rot13Once | ConvertFrom-AsciiToRot13
            $rot13Twice | Should -Be $original
        }
        
        It 'ROT13 only affects letters' {
            $testString = 'Hello123 World!'
            $result = $testString | ConvertFrom-AsciiToRot13
            $result | Should -Match '123'
            $result | Should -Match '!'
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToRot13
            $result | Should -Be ''
        }
    }

    Context 'ROT47 Cipher Conversions' {
        It 'ConvertFrom-AsciiToRot47 converts ASCII to ROT47' {
            $testString = 'Hello World!'
            $result = $testString | ConvertFrom-AsciiToRot47
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Rot47ToAscii converts ROT47 to ASCII' {
            $testRot47 = 'w6==@ (@C=5P'
            $result = $testRot47 | ConvertFrom-Rot47ToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ASCII to ROT47 and back roundtrip' {
            $original = 'Hello World!'
            $rot47 = $original | ConvertFrom-AsciiToRot47
            $decoded = $rot47 | ConvertFrom-Rot47ToAscii
            $decoded | Should -Be $original
        }
        
        It 'ROT47 is self-inverse (double application returns original)' {
            $original = 'Hello World!'
            $rot47Once = $original | ConvertFrom-AsciiToRot47
            $rot47Twice = $rot47Once | ConvertFrom-AsciiToRot47
            $rot47Twice | Should -Be $original
        }
        
        It 'ROT47 affects numbers and special characters' {
            $testString = 'Hello123 World!'
            $result = $testString | ConvertFrom-AsciiToRot47
            # ROT47 should change numbers and special characters
            $result | Should -Not -Be $testString
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToRot47
            $result | Should -Be ''
        }
    }
}

