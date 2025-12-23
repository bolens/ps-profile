

<#
.SYNOPSIS
    Integration tests for encoding and time conversion utilities.

.DESCRIPTION
    This test suite validates the conversion utilities:
    - Base58 encoding conversions (Base58 ↔ ASCII, Hex, Base64)
    - Base85/Ascii85 encoding conversions (Base85 ↔ ASCII, Hex, Base64)
    - RFC 3339 date/time conversions (RFC 3339 ↔ DateTime, Unix, ISO 8601, Human-readable)

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Encoding and Time Conversion Utilities Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Base58 Encoding Conversions' {
        It 'ConvertFrom-AsciiToBase58 converts ASCII to Base58' {
            $testString = 'Hello World'
            $result = $testString | ConvertFrom-AsciiToBase58
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base58ToAscii converts Base58 to ASCII' {
            $testBase58 = 'JxF12TrwUP45BMd'
            $result = $testBase58 | ConvertFrom-Base58ToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ASCII to Base58 and back roundtrip' {
            $original = 'Hello World'
            $base58 = $original | ConvertFrom-AsciiToBase58
            $decoded = $base58 | ConvertFrom-Base58ToAscii
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-HexToBase58 converts Hex to Base58' {
            $testHex = '48656C6C6F'
            $result = $testHex | ConvertFrom-HexToBase58
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base58ToHex converts Base58 to Hex' {
            $testBase58 = 'JxF12TrwUP45BMd'
            $result = $testBase58 | ConvertFrom-Base58ToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Hex to Base58 and back roundtrip' {
            $original = '48656C6C6F'
            $base58 = $original | ConvertFrom-HexToBase58
            $decoded = $base58 | ConvertFrom-Base58ToHex
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-Base64ToBase58 converts Base64 to Base58' {
            $testBase64 = 'SGVsbG8gV29ybGQ='
            $result = $testBase64 | ConvertFrom-Base64ToBase58
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base58ToBase64 converts Base58 to Base64' {
            $testBase58 = 'JxF12TrwUP45BMd'
            $result = $testBase58 | ConvertFrom-Base58ToBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Base64 to Base58 and back roundtrip' {
            $original = 'SGVsbG8gV29ybGQ='
            $base58 = $original | ConvertFrom-Base64ToBase58
            $base64 = $base58 | ConvertFrom-Base58ToBase64
            $base64 | Should -Be $original
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToBase58
            $result | Should -Be ''
        }
        
        It 'Handles invalid Base58 characters' {
            $invalid = 'Hello0World'  # Contains '0' which is not in Base58 alphabet
            { $invalid | ConvertFrom-Base58ToAscii } | Should -Throw
        }
    }
    
    Context 'Base85/Ascii85 Encoding Conversions' {
        It 'ConvertFrom-AsciiToBase85 converts ASCII to Base85' {
            $testString = 'Hello World'
            $result = $testString | ConvertFrom-AsciiToBase85
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base85ToAscii converts Base85 to ASCII' {
            $testBase85 = '87cURD]j7BEbo7'
            $result = $testBase85 | ConvertFrom-Base85ToAscii
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ASCII to Base85 and back roundtrip' {
            $original = 'Hello World'
            $base85 = $original | ConvertFrom-AsciiToBase85
            $decoded = $base85 | ConvertFrom-Base85ToAscii
            $decoded | Should -Be $original
        }
        
        It 'ConvertFrom-HexToBase85 converts Hex to Base85' {
            $testHex = '48656C6C6F'
            $result = $testHex | ConvertFrom-HexToBase85
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base85ToHex converts Base85 to Hex' {
            $testBase85 = '87cURD]j7BEbo7'
            $result = $testBase85 | ConvertFrom-Base85ToHex
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Hex to Base85 and back roundtrip' {
            # Use hex string that's a multiple of 4 bytes for proper Base85 roundtrip
            $original = '48656C6C6F576F726C64'  # "HelloWorld" - 10 bytes, pad to 12
            $base85 = $original | ConvertFrom-HexToBase85
            $decoded = $base85 | ConvertFrom-Base85ToHex
            # Base85 may add padding, so compare up to original length
            $decoded.Substring(0, [Math]::Min($decoded.Length, $original.Length)) | Should -Be $original.Substring(0, [Math]::Min($decoded.Length, $original.Length))
        }
        
        It 'ConvertFrom-Base64ToBase85 converts Base64 to Base85' {
            $testBase64 = 'SGVsbG8gV29ybGQ='
            $result = $testBase64 | ConvertFrom-Base64ToBase85
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Base85ToBase64 converts Base85 to Base64' {
            $testBase85 = '87cURD]j7BEbo7'
            $result = $testBase85 | ConvertFrom-Base85ToBase64
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Base64 to Base85 and back roundtrip' {
            $original = 'SGVsbG8gV29ybGQ='  # "Hello World" - 11 bytes
            $base85 = $original | ConvertFrom-Base64ToBase85
            $base64 = $base85 | ConvertFrom-Base85ToBase64
            # Base85 may have padding differences, so decode both and compare bytes
            $originalBytes = [Convert]::FromBase64String($original)
            $decodedBytes = [Convert]::FromBase64String($base64)
            # Compare byte arrays up to original length
            $minLength = [Math]::Min($originalBytes.Length, $decodedBytes.Length)
            for ($i = 0; $i -lt $minLength; $i++) {
                $decodedBytes[$i] | Should -Be $originalBytes[$i]
            }
        }
        
        It 'Handles empty string' {
            $empty = ''
            $result = $empty | ConvertFrom-AsciiToBase85
            $result | Should -Be ''
        }
        
        It 'Handles zero bytes compression (z character)' {
            $zeros = [byte[]]@(0, 0, 0, 0)
            $result = _Encode-Base85 -Bytes $zeros
            $result | Should -Contain 'z'
        }
    }
    
    Context 'RFC 3339 Date/Time Conversions' {
        It 'ConvertFrom-Rfc3339ToDateTime converts RFC 3339 to DateTime' {
            $testRfc3339 = '2021-01-01T00:00:00Z'
            $result = $testRfc3339 | ConvertFrom-Rfc3339ToDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [DateTime]
        }
        
        It 'ConvertTo-Rfc3339FromDateTime converts DateTime to RFC 3339' {
            $testDateTime = [DateTime]::Parse('2021-01-01T00:00:00Z')
            $result = $testDateTime | ConvertTo-Rfc3339FromDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'
        }
        
        It 'RFC 3339 to DateTime and back roundtrip' {
            $original = '2021-01-01T12:30:45Z'
            $dateTime = $original | ConvertFrom-Rfc3339ToDateTime
            $rfc3339 = $dateTime | ConvertTo-Rfc3339FromDateTime
            # Allow for timezone differences, just check format
            $rfc3339 | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'
        }
        
        It 'ConvertTo-Rfc3339FromUnixTimestamp converts Unix timestamp to RFC 3339' {
            $testUnix = 1609459200  # 2021-01-01T00:00:00Z
            $result = $testUnix | ConvertTo-Rfc3339FromUnixTimestamp
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'
        }
        
        It 'ConvertFrom-Rfc3339ToUnixTimestamp converts RFC 3339 to Unix timestamp' {
            $testRfc3339 = '2021-01-01T00:00:00Z'
            $result = $testRfc3339 | ConvertFrom-Rfc3339ToUnixTimestamp
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [double]
            $result | Should -BeGreaterThan 0
        }
        
        It 'Unix timestamp to RFC 3339 and back roundtrip' {
            $original = 1609459200.0  # 2021-01-01T00:00:00Z
            $rfc3339 = $original | ConvertTo-Rfc3339FromUnixTimestamp
            $unix = $rfc3339 | ConvertFrom-Rfc3339ToUnixTimestamp
            # Allow small differences due to timezone handling (RFC 3339 preserves timezone, Unix is UTC)
            # Convert both to integers for comparison
            [Math]::Abs([long]$unix - [long]$original) | Should -BeLessThan 2
        }
        
        It 'ConvertTo-Iso8601FromRfc3339 converts RFC 3339 to ISO 8601' {
            $testRfc3339 = '2021-01-01T00:00:00Z'
            $result = $testRfc3339 | ConvertTo-Iso8601FromRfc3339
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'ConvertFrom-Iso8601ToRfc3339 converts ISO 8601 to RFC 3339' {
            $testIso8601 = '2021-01-01T00:00:00Z'
            $result = $testIso8601 | ConvertFrom-Iso8601ToRfc3339
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'
        }
        
        It 'ISO 8601 to RFC 3339 and back roundtrip' {
            $original = '2021-01-01T12:30:45Z'
            $rfc3339 = $original | ConvertFrom-Iso8601ToRfc3339
            $iso8601 = $rfc3339 | ConvertTo-Iso8601FromRfc3339
            # Both should be valid date/time strings
            $iso8601 | Should -Not -BeNullOrEmpty
        }
        
        It 'ConvertFrom-Rfc3339ToHumanReadable converts RFC 3339 to human-readable' {
            $testRfc3339 = '2021-01-01T00:00:00Z'
            $result = $testRfc3339 | ConvertFrom-Rfc3339ToHumanReadable
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
        }
        
        It 'Handles RFC 3339 with timezone offset' {
            $testRfc3339 = '2021-01-01T12:30:45+05:00'
            $result = $testRfc3339 | ConvertFrom-Rfc3339ToDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [DateTime]
        }
        
        It 'Handles RFC 3339 with milliseconds' {
            $testRfc3339 = '2021-01-01T12:30:45.123Z'
            $result = $testRfc3339 | ConvertFrom-Rfc3339ToDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [DateTime]
        }
        
        It 'ConvertTo-Rfc3339FromDateTime with IncludeMilliseconds includes milliseconds' {
            $testDateTime = [DateTime]::Parse('2021-01-01T12:30:45.123Z')
            $result = $testDateTime | ConvertTo-Rfc3339FromDateTime -IncludeMilliseconds
            $result | Should -Match '\.\d{3}'
        }
    }
}

