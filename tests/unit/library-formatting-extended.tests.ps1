<#
tests/unit/library-formatting-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Invoke-CommandWithFallback and Get-CommandWithFallback.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'core' 'Formatting.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module Formatting -ErrorAction SilentlyContinue -Force
}

Describe 'Formatting extended scenarios' {
    Context 'Invoke-CommandWithFallback' {
        It 'Returns the fallback value when the command does not exist' {
            Invoke-CommandWithFallback -CommandName "MissingFormattingCmd_$(Get-Random)" -FallbackValue 'fallback-value' |
                Should -Be 'fallback-value'
        }

        It 'Executes the fallback script block when the command does not exist' {
            $result = Invoke-CommandWithFallback -CommandName "MissingFormattingCmd_$(Get-Random)" -FallbackScriptBlock {
                param($Multiplier)
                $Multiplier * 2
            } -Arguments @{ Multiplier = 21 }

            $result | Should -Be 42
        }

        It 'Invokes an existing command when it is available' {
            Invoke-CommandWithFallback -CommandName 'Get-Date' -Arguments @{ Year = 2024; Month = 6; Day = 7 } |
                Should -BeOfType [datetime]
        }
    }

    Context 'Get-CommandWithFallback' {
        It 'Returns the command object when the command exists' {
            $command = Get-CommandWithFallback -CommandName 'Get-Date' -FallbackValue 'unused-fallback'

            $command | Should -Not -BeNullOrEmpty
            $command.Name | Should -Be 'Get-Date'
        }

        It 'Returns the fallback value when the command does not exist' {
            Get-CommandWithFallback -CommandName "MissingGetCmd_$(Get-Random)" -FallbackValue 'missing' |
                Should -Be 'missing'
        }
    }
}
