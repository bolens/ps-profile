<#
tests/unit/library-module-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Module.psm1 import and availability helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $script:LibPath = Get-TestPath -RelativePath 'scripts\lib' -StartPath $PSScriptRoot -EnsureExists
    Import-Module (Join-Path $script:LibPath 'runtime' 'Module.psm1') -DisableNameChecking -Force
}

AfterAll {
    Remove-Module Module -ErrorAction SilentlyContinue -Force
}

Describe 'Module extended scenarios' {
    Context 'Import-RequiredModule' {
        It 'Does not throw when importing an already loaded module' {
            if (-not (Get-Module -ListAvailable -Name 'Pester' -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Pester is not available for import tests'
                return
            }

            Import-RequiredModule -ModuleName 'Pester' -ErrorAction SilentlyContinue
            { Import-RequiredModule -ModuleName 'Pester' } | Should -Not -Throw
        }

        It 'Requires ModuleName parameter' {
            (Get-Command Import-RequiredModule).Parameters.ContainsKey('ModuleName') | Should -Be $true
        }
    }

    Context 'Install-RequiredModule' {
        It 'Exposes Scope and Force parameters when ModuleScope is available' {
            $cmd = Get-Command Install-RequiredModule
            if (-not $cmd.Parameters -or $cmd.Parameters.Count -eq 0) {
                Set-ItResult -Skipped -Because 'Install-RequiredModule parameters not available'
                return
            }

            $cmd.Parameters.Keys | Should -Contain 'Scope'
            $cmd.Parameters.Keys | Should -Contain 'Force'
        }
    }

    Context 'Ensure-ModuleAvailable' {
        It 'Imports Pester without error when the module is already installed' {
            if (-not (Get-Module -ListAvailable -Name 'Pester' -ErrorAction SilentlyContinue)) {
                Set-ItResult -Skipped -Because 'Pester is not available'
                return
            }

            Remove-Module Pester -ErrorAction SilentlyContinue -Force
            { Ensure-ModuleAvailable -ModuleName 'Pester' } | Should -Not -Throw
            Get-Module Pester | Should -Not -BeNullOrEmpty
        }

        It 'Exports all three module helper functions' {
            $module = Get-Module Module
            @($module.ExportedFunctions.Keys) | Should -Contain 'Import-RequiredModule'
            @($module.ExportedFunctions.Keys) | Should -Contain 'Install-RequiredModule'
            @($module.ExportedFunctions.Keys) | Should -Contain 'Ensure-ModuleAvailable'
        }
    }
}
