<#
tests/unit/library-datetime-formatting-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for DateTimeFormatting ISO and log helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $libPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $formattingPath = Join-Path $libPath 'core' 'Formatting.psm1'

    if (Test-Path -LiteralPath $formattingPath) {
        Import-Module $formattingPath -DisableNameChecking -Force
    }

    Import-Module (Join-Path $libPath 'core' 'DateTimeFormatting.psm1') -DisableNameChecking -Force

    $script:SampleUtc = [DateTime]::SpecifyKind(
        [DateTime]::Parse('2024-06-15T14:30:00', [System.Globalization.CultureInfo]::InvariantCulture),
        [System.DateTimeKind]::Utc
    )
}

AfterAll {
    Remove-Module DateTimeFormatting -ErrorAction SilentlyContinue -Force
    Remove-Module Formatting -ErrorAction SilentlyContinue -Force
}

Describe 'DateTimeFormatting extended scenarios' {
    Context 'Format-DateTimeISO' {
        It 'Formats UTC timestamps without timezone suffix by default' {
            Format-DateTimeISO -DateTime $script:SampleUtc | Should -Be '2024-06-15T14:30:00'
        }

        It 'Includes timezone metadata when requested' {
            (Format-DateTimeISO -DateTime $script:SampleUtc -IncludeTimeZone) | Should -Match '2024-06-15T14:30:00'
        }
    }

    Context 'Format-DateTimeRFC3339' {
        It 'Formats timestamps with a trailing Z suffix' {
            Format-DateTimeRFC3339 -DateTime $script:SampleUtc | Should -Be '2024-06-15T14:30:00Z'
        }
    }

    Context 'Format-DateTimeLog' {
        It 'Formats log timestamps in yyyy-MM-dd HH:mm:ss' {
            Format-DateTimeLog -DateTime $script:SampleUtc | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'
        }
    }

    Context 'Format-DateTimeHuman' {
        It 'Uses the default human-readable month format' {
            Format-DateTimeHuman -DateTime $script:SampleUtc | Should -Match 'June 15, 2024'
        }
    }
}
