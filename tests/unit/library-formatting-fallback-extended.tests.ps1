<#
tests/unit/library-formatting-fallback-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Formatting fallback command helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'core' 'Formatting.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module Formatting -ErrorAction SilentlyContinue -Force
}

Describe 'Formatting fallback extended scenarios' {
    Context 'Format-DateWithFallback' {
        AfterEach {
            Remove-Item Function:\global:Format-LocaleDate -Force -ErrorAction SilentlyContinue
        }

        It 'Falls back when Format-LocaleDate throws during formatting' {
            function global:Format-LocaleDate {
                param([DateTime]$Date, [string]$Format)
                throw 'locale formatter unavailable'
            }

            $date = Get-Date '2024-06-01 12:00:00'
            $result = Format-DateWithFallback -Date $date -Format 'yyyy-MM-dd'

            $result | Should -Be '2024-06-01'
        }
    }

    Context 'Invoke-CommandWithFallback' {
        It 'Prefers fallback scriptblocks over fallback values' {
            $result = Invoke-CommandWithFallback -CommandName 'NonExistentFormattingCommand_Extended' `
                -FallbackValue 'value-result' `
                -FallbackScriptBlock { return 'scriptblock-result' }

            $result | Should -Be 'scriptblock-result'
        }

        It 'Executes commands without arguments when none are supplied' {
            $funcName = "Test-FormattingNoArgs_$(Get-Random)"
            Set-Item -Path "Function:\global:$funcName" -Value { return 'no-args' } -Force

            try {
                Invoke-CommandWithFallback -CommandName $funcName -FallbackValue 'fallback' |
                    Should -Be 'no-args'
            }
            finally {
                Remove-Item -Path "Function:\global:$funcName" -Force -ErrorAction SilentlyContinue
            }
        }
    }

    Context 'Get-CommandWithFallback' {
        It 'Returns command metadata for existing commands' {
            $command = Get-CommandWithFallback -CommandName 'Get-Date' -FallbackValue 'missing'

            $command | Should -Not -BeNullOrEmpty
            $command.Name | Should -Be 'Get-Date'
        }
    }
}
