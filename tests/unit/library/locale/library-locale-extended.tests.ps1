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
    }
}
