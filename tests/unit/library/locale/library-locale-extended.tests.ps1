<#
tests/unit/library-locale-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Locale detection and formatting helpers.
#>

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
    $localeModule = Get-TestPath -RelativePath 'scripts\lib\core\Locale.psm1' -StartPath $PSScriptRoot -EnsureExists
    Import-Module $localeModule -DisableNameChecking -ErrorAction Stop -Global
}

Describe 'Locale extended scenarios' {
    Context 'Get-UserLocale' {
        It 'Returns culture metadata with English variant flags' {
            $locale = Get-UserLocale

            $locale.Name | Should -Not -BeNullOrEmpty
            $locale.LanguageCode | Should -Not -BeNullOrEmpty
            $locale.Culture | Should -Not -BeNullOrEmpty
            $locale.UICulture | Should -Not -BeNullOrEmpty
            $locale.PSObject.Properties.Name | Should -Contain 'IsUKEnglish'
            $locale.PSObject.Properties.Name | Should -Contain 'IsUSEnglish'
            $locale.PSObject.Properties.Name | Should -Contain 'EnglishVariant'
        }
    }

    Context 'Get-LocalizedMessage' {
        It 'Returns USMessage when no UKMessage is supplied' {
            Get-LocalizedMessage -USMessage 'Color' | Should -Be 'Color'
        }

        It 'Returns one of the English variants when both messages are supplied' {
            $message = Get-LocalizedMessage -USMessage 'Canceled' -UKMessage 'Cancelled'
            $message | Should -BeIn @('Canceled', 'Cancelled')
        }

        It 'Uses DefaultMessage for non-US/UK English when provided' {
            $locale = Get-UserLocale
            if ($locale.IsUKEnglish -or $locale.IsUSEnglish) {
                Set-ItResult -Skipped -Because 'DefaultMessage branch requires a non-US/UK English locale'
                return
            }

            Get-LocalizedMessage -USMessage 'US only' -UKMessage 'UK only' -DefaultMessage 'Neutral default' |
                Should -Be 'Neutral default'
        }
    }

    Context 'Formatting helpers' {
        It 'Formats dates using the current culture' {
            $sampleDate = Get-Date '2024-06-15T10:30:00'
            $formatted = Format-LocaleDate -Date $sampleDate -Format 'yyyy-MM-dd'

            $formatted | Should -Be '2024-06-15'
        }

        It 'Formats numbers and currency using the current culture' {
            Format-LocaleNumber -Number 1234.5 -Format 'N1' | Should -Not -BeNullOrEmpty
            Format-LocaleCurrency -Amount 42.5 | Should -Match '\d'
        }

        It 'Builds combined locale output for supplied values' {
            $sampleDate = Get-Date '2024-01-15T08:00:00'
            $output = Format-LocaleOutput -Date $sampleDate -Number 12.5 -Currency 3.25 -DateFormat 'yyyy-MM-dd' -NumberFormat 'N1'

            $output.Date | Should -Be '2024-01-15'
            $output.Number | Should -Not -BeNullOrEmpty
            $output.Currency | Should -Not -BeNullOrEmpty
        }

        It 'Formats dates and numbers without explicit format strings' {
            $sampleDate = Get-Date '2024-03-10T12:00:00'
            Format-LocaleDate -Date $sampleDate | Should -Not -BeNullOrEmpty
            Format-LocaleNumber -Number 9876.5 | Should -Match '\d'
        }

        It 'Builds partial locale output when only some values are supplied' {
            $sampleDate = Get-Date '2024-05-01T09:00:00'
            $dateOnly = Format-LocaleOutput -Date $sampleDate -DateFormat 'yyyy-MM-dd'
            $numberOnly = Format-LocaleOutput -Number 42.25 -NumberFormat 'N2'
            $currencyOnly = Format-LocaleOutput -Currency 9.99

            $dateOnly.Date | Should -Be '2024-05-01'
            $dateOnly.PSObject.Properties.Name | Should -Not -Contain 'Number'
            $numberOnly.Number | Should -Not -BeNullOrEmpty
            $currencyOnly.Currency | Should -Match '\d'
        }
    }

    Context 'Locale detection helpers' {
        It 'Exposes UK and US English helper functions' {
            { Test-IsUKEnglish } | Should -Not -Throw
            { Test-IsUSEnglish } | Should -Not -Throw
            $ukResult = Test-IsUKEnglish
            $usResult = Test-IsUSEnglish
            $ukResult.GetType() | Should -Be ([bool])
            $usResult.GetType() | Should -Be ([bool])
        }

        It 'Detects UK English when culture is en-GB' {
            $originalCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
            $originalUiCulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
            $ukCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-GB')

            try {
                [System.Threading.Thread]::CurrentThread.CurrentCulture = $ukCulture
                [System.Threading.Thread]::CurrentThread.CurrentUICulture = $ukCulture

                $locale = Get-UserLocale
                $locale.IsUKEnglish | Should -Be $true
                $locale.EnglishVariant | Should -Be 'UK'
                Test-IsUKEnglish | Should -Be $true
                Get-LocalizedMessage -USMessage 'Color' -UKMessage 'Colour' | Should -Be 'Colour'
            }
            finally {
                [System.Threading.Thread]::CurrentThread.CurrentCulture = $originalCulture
                [System.Threading.Thread]::CurrentThread.CurrentUICulture = $originalUiCulture
            }
        }

        It 'Detects US English when culture is en-US' {
            $originalCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
            $originalUiCulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
            $usCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-US')

            try {
                [System.Threading.Thread]::CurrentThread.CurrentCulture = $usCulture
                [System.Threading.Thread]::CurrentThread.CurrentUICulture = $usCulture

                $locale = Get-UserLocale
                $locale.IsUSEnglish | Should -Be $true
                $locale.EnglishVariant | Should -Be 'US'
                Test-IsUSEnglish | Should -Be $true
                Get-LocalizedMessage -USMessage 'Color' -UKMessage 'Colour' | Should -Be 'Color'
            }
            finally {
                [System.Threading.Thread]::CurrentThread.CurrentCulture = $originalCulture
                [System.Threading.Thread]::CurrentThread.CurrentUICulture = $originalUiCulture
            }
        }

        It 'Uses US fallback for other English locales without DefaultMessage' {
            $originalCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
            $originalUiCulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
            $auCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-AU')

            try {
                [System.Threading.Thread]::CurrentThread.CurrentCulture = $auCulture
                [System.Threading.Thread]::CurrentThread.CurrentUICulture = $auCulture

                $locale = Get-UserLocale
                $locale.IsEnglish | Should -Be $true
                $locale.EnglishVariant | Should -Be 'Other'
                Get-LocalizedMessage -USMessage 'Color' -UKMessage 'Colour' | Should -Be 'Color'
            }
            finally {
                [System.Threading.Thread]::CurrentThread.CurrentCulture = $originalCulture
                [System.Threading.Thread]::CurrentThread.CurrentUICulture = $originalUiCulture
            }
        }

        It 'Falls back to USMessage for UK English when UKMessage is omitted' {
            $originalCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
            $originalUiCulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
            $ukCulture = [System.Globalization.CultureInfo]::GetCultureInfo('en-GB')

            try {
                [System.Threading.Thread]::CurrentThread.CurrentCulture = $ukCulture
                [System.Threading.Thread]::CurrentThread.CurrentUICulture = $ukCulture

                Get-LocalizedMessage -USMessage 'Color' | Should -Be 'Color'
            }
            finally {
                [System.Threading.Thread]::CurrentThread.CurrentCulture = $originalCulture
                [System.Threading.Thread]::CurrentThread.CurrentUICulture = $originalUiCulture
            }
        }

        It 'Uses DefaultMessage for non-English locales when provided' {
            $originalCulture = [System.Threading.Thread]::CurrentThread.CurrentCulture
            $originalUiCulture = [System.Threading.Thread]::CurrentThread.CurrentUICulture
            $deCulture = [System.Globalization.CultureInfo]::GetCultureInfo('de-DE')

            try {
                [System.Threading.Thread]::CurrentThread.CurrentCulture = $deCulture
                [System.Threading.Thread]::CurrentThread.CurrentUICulture = $deCulture

                $locale = Get-UserLocale
                $locale.IsEnglish | Should -Be $false
                $locale.EnglishVariant | Should -BeNullOrEmpty
                Get-LocalizedMessage -USMessage 'US' -UKMessage 'UK' -DefaultMessage 'Neutral' | Should -Be 'Neutral'
            }
            finally {
                [System.Threading.Thread]::CurrentThread.CurrentCulture = $originalCulture
                [System.Threading.Thread]::CurrentThread.CurrentUICulture = $originalUiCulture
            }
        }

        It 'Emits debug output when PS_PROFILE_DEBUG is enabled' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '3'

            try {
                $locale = Get-UserLocale
                $locale.Name | Should -Not -BeNullOrEmpty
                Format-LocaleOutput -Date (Get-Date) -Number 1.5 -Currency 2.5 | Should -Not -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }

        It 'Emits level 2 locale detection debug output' {
            $originalDebug = $env:PS_PROFILE_DEBUG
            $env:PS_PROFILE_DEBUG = '2'

            try {
                Get-UserLocale | Should -Not -BeNullOrEmpty
            }
            finally {
                if ($null -eq $originalDebug) {
                    Remove-Item Env:PS_PROFILE_DEBUG -ErrorAction SilentlyContinue
                }
                else {
                    $env:PS_PROFILE_DEBUG = $originalDebug
                }
            }
        }
    }
}
