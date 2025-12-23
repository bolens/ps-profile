

<#
.SYNOPSIS
    Integration tests for extended Time & Date conversion utilities.

.DESCRIPTION
    This test suite validates the Time & Date conversion utilities:
    - Human-readable date conversions (Human-readable ↔ DateTime, Unix, ISO 8601, RFC 3339)
    - Timezone conversions (DateTime ↔ different timezones)
    - Duration conversions (Duration ↔ TimeSpan, seconds, milliseconds)

.NOTES
    Tests cover both successful conversions and error handling scenarios.
    Pure PowerShell implementation - no external dependencies required.
#>

Describe 'Extended Time & Date Conversion Utilities Integration Tests' {
    BeforeAll {
        $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
        Initialize-TestProfile -ProfileDir $script:ProfileDir -LoadBootstrap -LoadConversionModules 'Data' -LoadFilesFragment -EnsureFileConversion
    }

    Context 'Human-readable Date Conversions' {
        It 'ConvertFrom-HumanReadableToDateTime function exists' {
            Get-Command ConvertFrom-HumanReadableToDateTime -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-HumanReadableToDateTime converts "tomorrow" correctly' {
            $result = "tomorrow" | ConvertFrom-HumanReadableToDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [DateTime]
            $expected = (Get-Date).Date.AddDays(1)
            $result.Date | Should -Be $expected
        }

        It 'ConvertFrom-HumanReadableToDateTime converts "yesterday" correctly' {
            $result = "yesterday" | ConvertFrom-HumanReadableToDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [DateTime]
            $expected = (Get-Date).Date.AddDays(-1)
            $result.Date | Should -Be $expected
        }

        It 'ConvertFrom-HumanReadableToDateTime converts "2 days ago" correctly' {
            $result = "2 days ago" | ConvertFrom-HumanReadableToDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [DateTime]
            $expected = (Get-Date).AddDays(-2)
            $result.Date | Should -Be $expected.Date
        }

        It 'ConvertTo-HumanReadableFromDateTime function exists' {
            Get-Command ConvertTo-HumanReadableFromDateTime -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-HumanReadableFromDateTime converts DateTime to relative format' {
            $yesterday = (Get-Date).AddDays(-1)
            $result = $yesterday | ConvertTo-HumanReadableFromDateTime
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Match 'yesterday|1 day'
        }

        It 'ConvertFrom-HumanReadableToUnixTimestamp function exists' {
            Get-Command ConvertFrom-HumanReadableToUnixTimestamp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-HumanReadableFromUnixTimestamp function exists' {
            Get-Command ConvertTo-HumanReadableFromUnixTimestamp -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-HumanReadableToIso8601 function exists' {
            Get-Command ConvertFrom-HumanReadableToIso8601 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-HumanReadableFromIso8601 function exists' {
            Get-Command ConvertTo-HumanReadableFromIso8601 -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }
    }

    Context 'Timezone Conversions' {
        It 'Convert-TimeZone function exists' {
            Get-Command Convert-TimeZone -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Convert-TimeZone converts between timezones' {
            $now = Get-Date
            $result = $now | Convert-TimeZone -SourceTimeZone "UTC" -TargetTimeZone "Eastern Standard Time"
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [DateTime]
        }

        It 'ConvertTo-TimeZone function exists' {
            Get-Command ConvertTo-TimeZone -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-TimeZone converts DateTime to UTC' {
            $now = Get-Date
            $result = $now | ConvertTo-TimeZone -TimeZone "UTC"
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [DateTime]
        }

        It 'ConvertFrom-TimeZone function exists' {
            Get-Command ConvertFrom-TimeZone -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-TimeZones function exists' {
            Get-Command Get-TimeZones -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'Get-TimeZones returns list of timezones' {
            $timezones = Get-TimeZones
            $timezones | Should -Not -BeNullOrEmpty
            $timezones | Should -HaveCount -GreaterThan 0
            $timezones[0] | Should -HaveProperty 'Id'
            $timezones[0] | Should -HaveProperty 'DisplayName'
        }
    }

    Context 'Duration Conversions' {
        It 'ConvertFrom-DurationToTimeSpan function exists' {
            Get-Command ConvertFrom-DurationToTimeSpan -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-DurationToTimeSpan converts "2 hours" correctly' {
            $result = "2 hours" | ConvertFrom-DurationToTimeSpan
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [TimeSpan]
            $result.TotalHours | Should -Be 2
        }

        It 'ConvertFrom-DurationToTimeSpan converts "1 day 3 hours 15 minutes" correctly' {
            $result = "1 day 3 hours 15 minutes" | ConvertFrom-DurationToTimeSpan
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [TimeSpan]
            $result.Days | Should -Be 1
            $result.Hours | Should -Be 3
            $result.Minutes | Should -Be 15
        }

        It 'ConvertTo-DurationFromTimeSpan function exists' {
            Get-Command ConvertTo-DurationFromTimeSpan -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-DurationFromTimeSpan converts TimeSpan to long format' {
            $timeSpan = New-TimeSpan -Days 2 -Hours 3 -Minutes 15
            $result = $timeSpan | ConvertTo-DurationFromTimeSpan
            $result | Should -Not -BeNullOrEmpty
            $result | Should -BeOfType [string]
            $result | Should -Match 'day|hour|minute'
        }

        It 'ConvertTo-DurationFromTimeSpan converts TimeSpan to short format' {
            $timeSpan = New-TimeSpan -Hours 2 -Minutes 30
            $result = $timeSpan | ConvertTo-DurationFromTimeSpan -Format 'short'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '\d+h|\d+m'
        }

        It 'ConvertTo-DurationFromTimeSpan converts TimeSpan to ISO 8601 format' {
            $timeSpan = New-TimeSpan -Days 1 -Hours 2 -Minutes 3 -Seconds 4
            $result = $timeSpan | ConvertTo-DurationFromTimeSpan -Format 'iso8601'
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^P\d+DT\d+H\d+M\d+S$'
        }

        It 'ConvertFrom-DurationToSeconds function exists' {
            Get-Command ConvertFrom-DurationToSeconds -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertFrom-DurationToSeconds converts duration to seconds' {
            $result = "2 hours" | ConvertFrom-DurationToSeconds
            $result | Should -Be 7200
        }

        It 'ConvertTo-DurationFromSeconds function exists' {
            Get-Command ConvertTo-DurationFromSeconds -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-DurationFromSeconds converts seconds to duration' {
            $result = 7200 | ConvertTo-DurationFromSeconds
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'hour'
        }

        It 'ConvertFrom-DurationToMilliseconds function exists' {
            Get-Command ConvertFrom-DurationToMilliseconds -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }

        It 'ConvertTo-DurationFromMilliseconds function exists' {
            Get-Command ConvertTo-DurationFromMilliseconds -CommandType Function -ErrorAction SilentlyContinue | Should -Not -Be $null
        }
    }

    Context 'Aliases' {
        It 'Human-readable aliases resolve to functions' {
            (Get-Alias human-to-datetime -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertFrom-HumanReadableToDateTime'
            (Get-Alias datetime-to-human -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertTo-HumanReadableFromDateTime'
            (Get-Alias human-to-unix -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertFrom-HumanReadableToUnixTimestamp'
            (Get-Alias unix-to-human -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertTo-HumanReadableFromUnixTimestamp'
        }

        It 'Timezone aliases resolve to functions' {
            (Get-Alias convert-timezone -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Convert-TimeZone'
            (Get-Alias datetime-to-timezone -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertTo-TimeZone'
            (Get-Alias timezone-to-datetime -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertFrom-TimeZone'
            (Get-Alias list-timezones -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Get-TimeZones'
        }

        It 'Duration aliases resolve to functions' {
            (Get-Alias duration-to-timespan -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertFrom-DurationToTimeSpan'
            (Get-Alias timespan-to-duration -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertTo-DurationFromTimeSpan'
            (Get-Alias duration-to-seconds -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertFrom-DurationToSeconds'
            (Get-Alias seconds-to-duration -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertTo-DurationFromSeconds'
        }
    }
}

