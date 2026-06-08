# ===============================================
# profile-utilities-datetime.tests.ps1
# Behavioral unit tests for DateTime utility functions
# ===============================================

BeforeAll {
    $current = Get-Item $PSScriptRoot
    while ($null -ne $current) {
        $testSupportPath = Join-Path $current.FullName 'TestSupport.ps1'
        if (Test-Path -LiteralPath $testSupportPath) {
            . $testSupportPath
            break
        }
        if ($current.Name -eq 'tests' -or $current.Parent -eq $null) { break }
        $current = $current.Parent
    }
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    $script:LibPath = Get-TestPath -RelativePath 'scripts/lib' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'utilities.ps1')
    Ensure-Utilities
}

Describe 'utilities-datetime.ps1 - epoch conversion' {
    It 'ConvertFrom-Epoch maps Unix epoch zero to the local equivalent of 1970-01-01 UTC' {
        $result = ConvertFrom-Epoch -epoch 0
        $expected = [DateTimeOffset]::FromUnixTimeSeconds(0).ToLocalTime()

        $result | Should -Be $expected
    }

    It 'ConvertTo-Epoch and ConvertFrom-Epoch round-trip a fixed instant' {
        $original = [datetime]'2024-06-15T12:30:00'
        $epoch = ConvertTo-Epoch -date $original
        $restored = ConvertFrom-Epoch -epoch $epoch

        $restored.Year | Should -Be $original.Year
        $restored.Month | Should -Be $original.Month
        $restored.Day | Should -Be $original.Day
        $restored.Hour | Should -Be $original.Hour
        $restored.Minute | Should -Be $original.Minute
    }

    It 'ConvertTo-Epoch defaults to the current local time when -date is omitted' {
        $before = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        $epoch = ConvertTo-Epoch
        $after = [DateTimeOffset]::Now.ToUnixTimeSeconds()

        $epoch | Should -BeGreaterOrEqual $before
        $epoch | Should -BeLessOrEqual $after
    }

    It 'Get-Epoch returns a current Unix timestamp' {
        $before = [DateTimeOffset]::Now.ToUnixTimeSeconds()
        $epoch = Get-Epoch
        $after = [DateTimeOffset]::Now.ToUnixTimeSeconds()

        $epoch | Should -BeGreaterOrEqual $before
        $epoch | Should -BeLessOrEqual $after
    }
}

Describe 'utilities-datetime.ps1 - Get-DateTime and aliases' {
    Context 'when Format-DateTime is available' {
        BeforeAll {
            Remove-Module DateTimeFormatting -ErrorAction SilentlyContinue -Force
            Remove-Module Formatting -ErrorAction SilentlyContinue -Force
            foreach ($name in @('Format-DateTime', 'Format-LocaleDate')) {
                Remove-Item -Path "Function:\global:$name" -Force -ErrorAction SilentlyContinue
            }

            $formattingPath = Join-Path $script:LibPath 'core' 'Formatting.psm1'
            if (Test-Path -LiteralPath $formattingPath) {
                Import-Module $formattingPath -DisableNameChecking -ErrorAction Stop -Force
            }

            $dateTimeFormattingPath = Join-Path $script:LibPath 'core' 'DateTimeFormatting.psm1'
            Import-Module $dateTimeFormattingPath -DisableNameChecking -ErrorAction Stop -Force
        }

        AfterAll {
            Remove-Module DateTimeFormatting -ErrorAction SilentlyContinue -Force
            Remove-Module Formatting -ErrorAction SilentlyContinue -Force
        }

        It 'Delegates to Format-DateTime with the standard timestamp format' {
            Get-Command Format-DateTime -ErrorAction Stop | Should -Not -BeNullOrEmpty

            $output = Get-DateTime

            $output | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'
            [datetime]::ParseExact($output, 'yyyy-MM-dd HH:mm:ss', $null) | Should -Not -BeNullOrEmpty
        }
    }

    Context 'when only Format-LocaleDate is available' {
        BeforeEach {
            Remove-Module DateTimeFormatting -ErrorAction SilentlyContinue -Force
            foreach ($name in @('Format-DateTime', 'Format-LocaleDate')) {
                Remove-Item -Path "Function:\global:$name" -Force -ErrorAction SilentlyContinue
            }

            Set-Item -Path Function:\global:Format-LocaleDate -Value {
                param(
                    [datetime]$Date,
                    [string]$Format
                )

                if ($Format -ne 'yyyy-MM-dd HH:mm:ss') {
                    throw "Unexpected format: $Format"
                }

                return '2000-01-02 03:04:05'
            }.GetNewClosure() -Force
        }

        It 'Delegates to Format-LocaleDate when Format-DateTime is unavailable' {
            Get-Command Format-DateTime -ErrorAction SilentlyContinue | Should -BeNullOrEmpty
            Get-DateTime | Should -Be '2000-01-02 03:04:05'
        }
    }

    Context 'when no formatting helpers are available' {
        BeforeEach {
            Remove-Module DateTimeFormatting -ErrorAction SilentlyContinue -Force
            foreach ($name in @('Format-DateTime', 'Format-LocaleDate')) {
                Remove-Item -Path "Function:\global:$name" -Force -ErrorAction SilentlyContinue
            }
        }

        It 'Falls back to Get-Date formatting when format helpers are unavailable' {
            $output = Get-DateTime

            $output | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}$'
            [datetime]::ParseExact($output, 'yyyy-MM-dd HH:mm:ss', $null) | Should -Not -BeNullOrEmpty
        }
    }

    It 'Registers epoch conversion aliases that resolve to the underlying functions' {
        (Get-Command from-epoch -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertFrom-Epoch'
        (Get-Command to-epoch -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'ConvertTo-Epoch'
        (Get-Command epoch -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Get-Epoch'
        (Get-Command now -ErrorAction SilentlyContinue).ResolvedCommandName | Should -Be 'Get-DateTime'
    }
}
