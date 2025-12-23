

<#
.SYNOPSIS
    Integration tests for ISO 8601 conversion utilities.

.DESCRIPTION
    This test suite validates ISO 8601 conversion functions including conversions to/from DateTime, Unix timestamp, RFC 3339, and human-readable formats.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'ISO 8601 Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'ISO 8601 Conversions' {
        It 'ConvertFrom-Iso8601ToDateTime converts ISO 8601 to DateTime' {
            Get-Command ConvertFrom-Iso8601ToDateTime -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $iso8601 = '2021-01-01T00:00:00Z'
            $result = $iso8601 | ConvertFrom-Iso8601ToDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [DateTime]
        }

        It 'ConvertTo-Iso8601FromDateTime converts DateTime to ISO 8601' {
            Get-Command ConvertTo-Iso8601FromDateTime -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $dateTime = [DateTime]::Parse('2021-01-01 00:00:00')
            $result = $dateTime | ConvertTo-Iso8601FromDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T'
        }

        It 'ISO 8601 to DateTime and back roundtrip' {
            $originalIso8601 = '2021-01-01T00:00:00Z'
            $dateTime = $originalIso8601 | ConvertFrom-Iso8601ToDateTime
            $roundtripIso8601 = $dateTime | ConvertTo-Iso8601FromDateTime
            $roundtripIso8601 | Should -Not -BeNullOrEmpty
            $roundtripIso8601 | Should -Match '^\d{4}-\d{2}-\d{2}T'
        }

        It 'ConvertFrom-Iso8601ToUnixTimestamp converts ISO 8601 to Unix timestamp' {
            Get-Command ConvertFrom-Iso8601ToUnixTimestamp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $iso8601 = '2021-01-01T00:00:00Z'
            $result = $iso8601 | ConvertFrom-Iso8601ToUnixTimestamp
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [long]
        }

        It 'ConvertTo-Iso8601FromUnixTimestamp converts Unix timestamp to ISO 8601' {
            Get-Command ConvertTo-Iso8601FromUnixTimestamp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $unixTimestamp = 1609459200
            $result = $unixTimestamp | ConvertTo-Iso8601FromUnixTimestamp
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T'
        }

        It 'ConvertFrom-Iso8601ToRfc3339 converts ISO 8601 to RFC 3339' {
            Get-Command ConvertFrom-Iso8601ToRfc3339 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $iso8601 = '2021-01-01T00:00:00Z'
            $result = $iso8601 | ConvertFrom-Iso8601ToRfc3339
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T'
        }

        It 'ConvertFrom-Iso8601ToHumanReadable converts ISO 8601 to human-readable' {
            Get-Command ConvertFrom-Iso8601ToHumanReadable -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $iso8601 = '2021-01-01T00:00:00Z'
            $result = $iso8601 | ConvertFrom-Iso8601ToHumanReadable
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '2021'
        }
    }
}

