. (Join-Path $PSScriptRoot '..\TestSupport.ps1')

BeforeAll {
    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    $script:DateTimeFormattingPath = Join-Path $script:LibPath 'core' 'DateTimeFormatting.psm1'
    
    # Import Formatting module first (dependency)
    $formattingPath = Join-Path $script:LibPath 'core' 'Formatting.psm1'
    if (Test-Path $formattingPath) {
        Import-Module $formattingPath -DisableNameChecking -ErrorAction SilentlyContinue -Force
    }
    
    # Import the module under test
    Import-Module $script:DateTimeFormattingPath -DisableNameChecking -ErrorAction Stop -Force
}

AfterAll {
    Remove-Module DateTimeFormatting -ErrorAction SilentlyContinue -Force
    Remove-Module Formatting -ErrorAction SilentlyContinue -Force
}

Describe 'DateTimeFormatting Module Functions' {
    Context 'Format-DateTime' {
        BeforeEach {
            # Remove Formatting module to ensure Format-DateWithFallback is not available
            $script:formattingModule = Get-Module Formatting -ErrorAction SilentlyContinue
            if ($script:formattingModule) {
                Remove-Module Formatting -Force -ErrorAction SilentlyContinue
            }
            
            # Remove Locale module if it exists (exports Format-LocaleDate)
            $script:localeModule = Get-Module Locale -ErrorAction SilentlyContinue
            if ($script:localeModule) {
                Remove-Module Locale -Force -ErrorAction SilentlyContinue
            }
            
            # Ensure Format-LocaleDate and Format-DateWithFallback are not available by default for these tests
            # Remove from function provider (might be a function or from a module)
            $script:originalFormatLocaleDate = Get-Command Format-LocaleDate -ErrorAction SilentlyContinue
            $script:originalFormatDateWithFallback = Get-Command Format-DateWithFallback -ErrorAction SilentlyContinue
            
            # Force remove Format-LocaleDate from all possible locations
            if ($script:originalFormatLocaleDate) {
                Remove-Item -Path Function:\global:Format-LocaleDate -Force -ErrorAction SilentlyContinue
                Remove-Item -Path Alias:\global:Format-LocaleDate -Force -ErrorAction SilentlyContinue
            }
            # Also remove any mock that might have been created by previous tests
            Remove-Item -Path Function:\global:Format-LocaleDate -Force -ErrorAction SilentlyContinue
            
            if ($script:originalFormatDateWithFallback) {
                Remove-Item -Path Function:\global:Format-DateWithFallback -Force -ErrorAction SilentlyContinue
                Remove-Item -Path Alias:\global:Format-DateWithFallback -Force -ErrorAction SilentlyContinue
            }
            # Also remove any mock that might have been created
            Remove-Item -Path Function:\global:Format-DateWithFallback -Force -ErrorAction SilentlyContinue
            
            # Double-check that Format-LocaleDate is really gone
            $remainingCmd = Get-Command Format-LocaleDate -ErrorAction SilentlyContinue
            if ($remainingCmd) {
                # Force remove any remaining references
                Get-Command Format-LocaleDate -All -ErrorAction SilentlyContinue | ForEach-Object {
                    if ($_.Module) {
                        Remove-Module $_.Module.Name -Force -ErrorAction SilentlyContinue
                    }
                }
                Remove-Item -Path Function:\global:Format-LocaleDate -Force -ErrorAction SilentlyContinue
            }
            
            # Reload DateTimeFormatting module so it re-checks for Format-DateWithFallback
            Remove-Module DateTimeFormatting -Force -ErrorAction SilentlyContinue
            Import-Module $script:DateTimeFormattingPath -DisableNameChecking -ErrorAction Stop -Force
        }
        
        AfterEach {
            # Restore Formatting module if it existed
            if ($script:formattingModule) {
                Import-Module (Join-Path $script:LibPath 'core' 'Formatting.psm1') -DisableNameChecking -ErrorAction SilentlyContinue -Force
            }
            # Restore Locale module if it existed
            if ($script:localeModule) {
                Import-Module (Join-Path $script:LibPath 'core' 'Locale.psm1') -DisableNameChecking -ErrorAction SilentlyContinue -Force
            }
            # Restore Format-LocaleDate and Format-DateWithFallback if they existed
            if ($script:originalFormatLocaleDate) {
                Set-Item -Path Function:\global:Format-LocaleDate -Value $script:originalFormatLocaleDate.ScriptBlock -Force
            }
            if ($script:originalFormatDateWithFallback) {
                Set-Item -Path Function:\global:Format-DateWithFallback -Value $script:originalFormatDateWithFallback.ScriptBlock -Force
            }
            # Reload DateTimeFormatting module to restore normal behavior
            Remove-Module DateTimeFormatting -Force -ErrorAction SilentlyContinue
            Import-Module $script:DateTimeFormattingPath -DisableNameChecking -ErrorAction Stop -Force
        }
        
        It 'Formats date with specified format' {
            # BeforeEach already removed modules and reloaded DateTimeFormatting
            # Test that the result doesn't have LOCALE: prefix
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTime -DateTime $date -Format 'yyyy-MM-dd HH:mm:ss'
            $result | Should -Be '2024-01-15 14:30:00'
            $result | Should -Not -Match '^LOCALE:'
        }

        It 'Falls back to standard formatting when Format-LocaleDate is not available' {
            # BeforeEach already removed modules and reloaded DateTimeFormatting
            # Test that the result doesn't have LOCALE: prefix (which would indicate Format-LocaleDate was used)
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTime -DateTime $date -Format 'yyyy-MM-dd'
            $result | Should -Be '2024-01-15'
            $result | Should -Not -Match '^LOCALE:'
        }

        It 'Uses custom culture when provided' {
            # BeforeEach already removed modules and reloaded DateTimeFormatting
            # Test that the result doesn't have LOCALE: prefix
            $date = Get-Date '2024-01-15 14:30:00'
            $culture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')
            $result = Format-DateTime -DateTime $date -Format 'yyyy-MM-dd' -Culture $culture
            $result | Should -Be '2024-01-15'
            $result | Should -Not -Match '^LOCALE:'
        }
    }

    Context 'Format-DateTimeISO' {
        It 'Formats date in ISO 8601 format' {
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTimeISO -DateTime $date
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'
        }

        It 'Uses UTC time by default' {
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTimeISO -DateTime $date
            # Should not contain timezone offset when IncludeTimeZone is false
            $result | Should -Not -Match '[+-]\d{2}:\d{2}'
        }

        It 'Includes timezone when specified' {
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTimeISO -DateTime $date -IncludeTimeZone
            $result | Should -Match 'Z$|[\+-]\d{2}:\d{2}$'
        }

        It 'Uses current UTC time when DateTime not provided' {
            $result = Format-DateTimeISO
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}'
        }

        It 'Converts local time to UTC' {
            $localDate = Get-Date '2024-01-15 14:30:00'
            $utcDate = $localDate.ToUniversalTime()
            $result = Format-DateTimeISO -DateTime $localDate
            $expected = Format-DateTimeISO -DateTime $utcDate
            $result | Should -Be $expected
        }
    }

    Context 'Format-DateTimeLog' {
        BeforeEach {
            # Remove Formatting module to ensure Format-DateWithFallback is not available
            $script:formattingModule = Get-Module Formatting -ErrorAction SilentlyContinue
            if ($script:formattingModule) {
                Remove-Module Formatting -Force -ErrorAction SilentlyContinue
            }
            
            # Remove Locale module if it exists (exports Format-LocaleDate)
            $script:localeModule = Get-Module Locale -ErrorAction SilentlyContinue
            if ($script:localeModule) {
                Remove-Module Locale -Force -ErrorAction SilentlyContinue
            }
            
            # Ensure Format-LocaleDate and Format-DateWithFallback are not available
            # Remove from function provider (might be a function or from a module)
            $script:originalFormatLocaleDate = Get-Command Format-LocaleDate -ErrorAction SilentlyContinue
            $script:originalFormatDateWithFallback = Get-Command Format-DateWithFallback -ErrorAction SilentlyContinue
            
            # Force remove Format-LocaleDate from all possible locations
            if ($script:originalFormatLocaleDate) {
                Remove-Item -Path Function:\global:Format-LocaleDate -Force -ErrorAction SilentlyContinue
                Remove-Item -Path Alias:\global:Format-LocaleDate -Force -ErrorAction SilentlyContinue
            }
            # Also remove any mock that might have been created by previous tests
            Remove-Item -Path Function:\global:Format-LocaleDate -Force -ErrorAction SilentlyContinue
            
            if ($script:originalFormatDateWithFallback) {
                Remove-Item -Path Function:\global:Format-DateWithFallback -Force -ErrorAction SilentlyContinue
                Remove-Item -Path Alias:\global:Format-DateWithFallback -Force -ErrorAction SilentlyContinue
            }
            # Also remove any mock that might have been created
            Remove-Item -Path Function:\global:Format-DateWithFallback -Force -ErrorAction SilentlyContinue
            
            # Double-check that Format-LocaleDate is really gone
            $remainingCmd = Get-Command Format-LocaleDate -ErrorAction SilentlyContinue
            if ($remainingCmd) {
                # Force remove any remaining references
                Get-Command Format-LocaleDate -All -ErrorAction SilentlyContinue | ForEach-Object {
                    if ($_.Module) {
                        Remove-Module $_.Module.Name -Force -ErrorAction SilentlyContinue
                    }
                }
                Remove-Item -Path Function:\global:Format-LocaleDate -Force -ErrorAction SilentlyContinue
            }
            
            # Reload DateTimeFormatting module so it re-checks for Format-DateWithFallback
            Remove-Module DateTimeFormatting -Force -ErrorAction SilentlyContinue
            Import-Module $script:DateTimeFormattingPath -DisableNameChecking -ErrorAction Stop -Force
        }
        
        AfterEach {
            # Restore Formatting module if it existed
            if ($script:formattingModule) {
                Import-Module (Join-Path $script:LibPath 'core' 'Formatting.psm1') -DisableNameChecking -ErrorAction SilentlyContinue -Force
            }
            # Restore Locale module if it existed
            if ($script:localeModule) {
                Import-Module (Join-Path $script:LibPath 'core' 'Locale.psm1') -DisableNameChecking -ErrorAction SilentlyContinue -Force
            }
            if ($script:originalFormatLocaleDate) {
                Set-Item -Path Function:\global:Format-LocaleDate -Value $script:originalFormatLocaleDate.ScriptBlock -Force
            }
            # Reload DateTimeFormatting module to restore normal behavior
            Remove-Module DateTimeFormatting -Force -ErrorAction SilentlyContinue
            Import-Module $script:DateTimeFormattingPath -DisableNameChecking -ErrorAction Stop -Force
        }
        
        It 'Formats date in log format' {
            # BeforeEach already removed modules and reloaded DateTimeFormatting
            # Format-DateTimeLog converts to UTC by default, so we need to account for that
            $date = Get-Date '2024-01-15 14:30:00'
            $utcDate = $date.ToUniversalTime()
            $result = Format-DateTimeLog -DateTime $date
            # The function converts to UTC by default, so compare with UTC time
            $expected = Format-DateTime -DateTime $utcDate -Format 'yyyy-MM-dd HH:mm:ss'
            $result | Should -Be $expected
            $result | Should -Not -Match '^LOCALE:'
        }

        It 'Uses UTC time by default' {
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTimeLog -DateTime $date
            $result | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
        }

        It 'Uses local time when UseUTC is false' {
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTimeLog -DateTime $date -UseUTC $false
            $result | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
        }

        It 'Uses current UTC time when DateTime not provided' {
            $result = Format-DateTimeLog
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^\d{4}-\d{2}-\d{2} \d{2}:\d{2}:\d{2}'
        }

        It 'Converts to UTC when UseUTC is true' {
            $localDate = Get-Date '2024-01-15 14:30:00'
            $utcDate = $localDate.ToUniversalTime()
            $result = Format-DateTimeLog -DateTime $localDate -UseUTC $true
            $expected = Format-DateTimeLog -DateTime $utcDate -UseUTC $true
            $result | Should -Be $expected
        }
    }

    Context 'Format-DateTimeRFC3339' {
        It 'Formats date in RFC 3339 format' {
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTimeRFC3339 -DateTime $date
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
        }

        It 'Uses UTC time' {
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTimeRFC3339 -DateTime $date
            # Verify it's in UTC format (ends with Z)
            $result | Should -Match 'Z$'
        }

        It 'Uses current UTC time when DateTime not provided' {
            $result = Format-DateTimeRFC3339
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match '^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$'
        }

        It 'Converts local time to UTC' {
            $localDate = Get-Date '2024-01-15 14:30:00'
            $utcDate = $localDate.ToUniversalTime()
            $result = Format-DateTimeRFC3339 -DateTime $localDate
            $expected = Format-DateTimeRFC3339 -DateTime $utcDate
            $result | Should -Be $expected
        }
    }

    Context 'Format-DateTimeHuman' {
        It 'Formats date in human-readable format' {
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTimeHuman -DateTime $date
            $result | Should -Not -BeNullOrEmpty
            $result | Should -Match 'January|Jan'
        }

        It 'Uses custom format when provided' {
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTimeHuman -DateTime $date -Format 'yyyy-MM-dd'
            $result | Should -Be '2024-01-15'
        }

        It 'Uses default format when not specified' {
            $date = Get-Date '2024-01-15 14:30:00'
            $result = Format-DateTimeHuman -DateTime $date
            # Default format is 'MMMM d, yyyy'
            $result | Should -Match 'January 15, 2024|Jan 15, 2024'
        }

        It 'Uses Format-LocaleDate when available' {
            # Create a mock Format-LocaleDate function in global scope
            $mockBody = {
                param([DateTime]$Date, [string]$Format)
                return "LOCALE:$($Date.ToString($Format))"
            }
            
            $originalCmd = Get-Command Format-LocaleDate -ErrorAction SilentlyContinue
            if (-not $originalCmd) {
                Set-Item -Path Function:\global:Format-LocaleDate -Value $mockBody -Force
            }
            
            try {
                $date = Get-Date '2024-01-15 14:30:00'
                $result = Format-DateTimeHuman -DateTime $date -Format 'yyyy-MM-dd'
                $result | Should -Match 'LOCALE:'
            }
            finally {
                if (-not $originalCmd) {
                    Remove-Item -Path Function:\global:Format-LocaleDate -Force -ErrorAction SilentlyContinue
                }
            }
        }
    }
}

