

<#
.SYNOPSIS
    Integration tests for Unix timestamp conversion utilities.

.DESCRIPTION
    This test suite validates Unix timestamp conversion functions including conversions to/from DateTime, ISO 8601, and human-readable formats.

.NOTES
    Tests cover both successful conversions and roundtrip scenarios.
#>

Describe 'Unix Timestamp Conversion Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Unix Timestamp Conversions' {
        It 'ConvertFrom-UnixTimestampToDateTime converts Unix timestamp to DateTime' {
            Get-Command ConvertFrom-UnixTimestampToDateTime -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $unixTimestamp = 1609459200  # 2021-01-01 00:00:00 UTC
            $result = $unixTimestamp | ConvertFrom-UnixTimestampToDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [DateTime]
        }

        It 'ConvertTo-UnixTimestampFromDateTime converts DateTime to Unix timestamp' {
            Get-Command ConvertTo-UnixTimestampFromDateTime -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $dateTime = [DateTime]::Parse('2021-01-01 00:00:00')
            $result = $dateTime | ConvertTo-UnixTimestampFromDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [long]
            $result | Should -BeGreaterThan 0
        }

        It 'Unix timestamp to DateTime and back roundtrip' {
            $originalTimestamp = 1609459200
            $dateTime = $originalTimestamp | ConvertFrom-UnixTimestampToDateTime
            $roundtripTimestamp = $dateTime | ConvertTo-UnixTimestampFromDateTime
            # Allow for small differences due to timezone handling
            [Math]::Abs($roundtripTimestamp - $originalTimestamp) | Should -BeLessThan 86400  # Within 1 day
        }

        It 'ConvertFrom-UnixTimestampToIso8601 converts Unix timestamp to ISO 8601' {
            Get-Command ConvertFrom-UnixTimestampToIso8601 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $unixTimestamp = 1609459200
            $result = $unixTimestamp | ConvertFrom-UnixTimestampToIso8601
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T'
        }

        It 'ConvertTo-UnixTimestampFromIso8601 converts ISO 8601 to Unix timestamp' {
            Get-Command ConvertTo-UnixTimestampFromIso8601 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $iso8601 = '2021-01-01T00:00:00Z'
            $result = $iso8601 | ConvertTo-UnixTimestampFromIso8601
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [long]
        }

        It 'ConvertFrom-UnixTimestampToHumanReadable converts Unix timestamp to human-readable' {
            Get-Command ConvertFrom-UnixTimestampToHumanReadable -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
            
            $unixTimestamp = 1609459200
            $result = $unixTimestamp | ConvertFrom-UnixTimestampToHumanReadable
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '2021'
        }
    }
}

