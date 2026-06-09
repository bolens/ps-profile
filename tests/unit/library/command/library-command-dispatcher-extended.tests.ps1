<#
tests/unit/library-command-dispatcher-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for CommandDispatcher auto-load and handler chaining.
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

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $fragmentLib = Join-Path $script:RepoRoot 'scripts' 'lib' 'fragment'
    Import-Module (Join-Path $fragmentLib 'FragmentCommandRegistry.psm1') -DisableNameChecking -Force
    Import-Module (Join-Path $fragmentLib 'CommandDispatcher.psm1') -DisableNameChecking -Force
}

AfterAll {
    if (Get-Command Unregister-CommandDispatcher -ErrorAction SilentlyContinue) {
        Unregister-CommandDispatcher | Out-Null
    }

    Remove-Item Function:\Load-FragmentForCommand -ErrorAction SilentlyContinue -Force
    Remove-Item Function:\Invoke-WithWideEvent -ErrorAction SilentlyContinue -Force
    Remove-Item Function:\DispatcherExtendedTestCmd -ErrorAction SilentlyContinue -Force
    Remove-Module CommandDispatcher, FragmentCommandRegistry -ErrorAction SilentlyContinue -Force
}

Describe 'CommandDispatcher extended scenarios' {
    BeforeEach {
        Unregister-CommandDispatcher -ErrorAction SilentlyContinue | Out-Null
        Initialize-FragmentCommandRegistry
        $global:FragmentCommandRegistry.Clear()
        $env:PS_PROFILE_AUTO_LOAD_FRAGMENTS = '1'
    }

    AfterEach {
        Unregister-CommandDispatcher -ErrorAction SilentlyContinue | Out-Null
        Remove-Item Function:\Load-FragmentForCommand -ErrorAction SilentlyContinue -Force
        Remove-Item Function:\Invoke-WithWideEvent -ErrorAction SilentlyContinue -Force
        Remove-Item Function:\DispatcherExtendedTestCmd -ErrorAction SilentlyContinue -Force
        Remove-Item Env:PS_PROFILE_AUTO_LOAD_TIMEOUT -ErrorAction SilentlyContinue
        Remove-Item Env:PS_PROFILE_AUTO_LOAD_FRAGMENTS -ErrorAction SilentlyContinue
    }

    Context 'Auto-load configuration helpers' {
        It 'Defaults auto-load to enabled when the environment variable is unset' {
            Remove-Item Env:PS_PROFILE_AUTO_LOAD_FRAGMENTS -ErrorAction SilentlyContinue

            InModuleScope -ModuleName CommandDispatcher {
                Test-AutoLoadFragmentsEnabled | Should -Be $true
            }
        }

        It 'Parses positive timeout values from the environment' {
            $env:PS_PROFILE_AUTO_LOAD_TIMEOUT = '45'

            InModuleScope -ModuleName CommandDispatcher {
                Get-AutoLoadTimeoutSeconds | Should -Be 45
            }
        }

        It 'Falls back to the default timeout for zero or invalid values' {
            $env:PS_PROFILE_AUTO_LOAD_TIMEOUT = '0'

            InModuleScope -ModuleName CommandDispatcher {
                Get-AutoLoadTimeoutSeconds | Should -Be 30
            }

            $env:PS_PROFILE_AUTO_LOAD_TIMEOUT = 'not-a-number'
            InModuleScope -ModuleName CommandDispatcher {
                Get-AutoLoadTimeoutSeconds | Should -Be 30
            }
        }
    }

    Context 'Invoke-CommandDispatcher resolution paths' {
        It 'Returns false when the registry is unavailable' {
            $originalRegistry = $global:FragmentCommandRegistry
            try {
                Remove-Variable -Name FragmentCommandRegistry -Scope Global -ErrorAction SilentlyContinue
                Invoke-CommandDispatcher -CommandName 'AnyCmd' | Should -Be $false
            }
            finally {
                $global:FragmentCommandRegistry = $originalRegistry
            }
        }

        It 'Resolves commands after fragment loading and updates lookup event args' {
            Register-FragmentCommand -CommandName 'DispatcherExtendedTestCmd' -FragmentName 'bootstrap' -CommandType 'Function' | Out-Null

            function global:Load-FragmentForCommand {
                param([string]$CommandName)
                if ($CommandName -eq 'DispatcherExtendedTestCmd') {
                    function global:DispatcherExtendedTestCmd { 'loaded' }
                    return $true
                }
                return $false
            }

            $eventArgs = [PSCustomObject]@{
                CommandFound = $null
                StopSearch   = $true
            }

            Invoke-CommandDispatcher -CommandName 'DispatcherExtendedTestCmd' -CommandLookupEventArgs $eventArgs |
                Should -Be $true
            $eventArgs.CommandFound.Name | Should -Be 'DispatcherExtendedTestCmd'
            $eventArgs.StopSearch | Should -Be $false
        }

        It 'Uses the direct dispatch path when Invoke-WithWideEvent is unavailable' {
            Register-FragmentCommand -CommandName 'DispatcherExtendedTestCmd' -FragmentName 'bootstrap' -CommandType 'Function' | Out-Null
            Remove-Item Function:\Invoke-WithWideEvent -ErrorAction SilentlyContinue -Force

            function global:Load-FragmentForCommand {
                param([string]$CommandName)
                if ($CommandName -eq 'DispatcherExtendedTestCmd') {
                    function global:DispatcherExtendedTestCmd { 'loaded-direct' }
                    return $true
                }
                return $false
            }

            Invoke-CommandDispatcher -CommandName 'DispatcherExtendedTestCmd' | Should -Be $true
        }
    }

    Context 'Registry availability helpers' {
        It 'Reports registry availability through Test-RegistryAvailable' {
            InModuleScope -ModuleName CommandDispatcher {
                Test-RegistryAvailable | Should -Be $true
            }

            $originalRegistry = $global:FragmentCommandRegistry
            try {
                Remove-Variable -Name FragmentCommandRegistry -Scope Global -ErrorAction SilentlyContinue
                InModuleScope -ModuleName CommandDispatcher {
                    Test-RegistryAvailable | Should -Be $false
                }
            }
            finally {
                $global:FragmentCommandRegistry = $originalRegistry
            }
        }
    }
}
