<#
tests/integration/bootstrap/fragment-command-access.tests.ps1

.SYNOPSIS
    Integration tests for fragment command access wiring in bootstrap and FunctionRegistration.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\..\TestSupport.ps1')

    $script:RepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:FragmentLibDir = Join-Path $script:RepoRoot 'scripts' 'lib' 'fragment'
    $script:BootstrapPath = Get-TestPath -RelativePath 'profile.d\bootstrap.ps1' -StartPath $PSScriptRoot -EnsureExists
    $script:RegistryModulePath = Join-Path $script:FragmentLibDir 'FragmentCommandRegistry.psm1'
    $script:LoaderModulePath = Join-Path $script:FragmentLibDir 'FragmentLoader.psm1'
    $script:DispatcherModulePath = Join-Path $script:FragmentLibDir 'CommandDispatcher.psm1'

    . $script:BootstrapPath
}

Describe 'Fragment command access integration' {
    Context 'Bootstrap optional module loading' {
        It 'Exposes bootstrap registration helpers after load' {
            Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command New-FragmentCommandProxy -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Register-LazyFunction -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }

        It 'Loads fragment command access modules from scripts/lib/fragment' {
            Test-Path -LiteralPath $script:RegistryModulePath | Should -Be $true
            Test-Path -LiteralPath $script:LoaderModulePath | Should -Be $true
            Test-Path -LiteralPath $script:DispatcherModulePath | Should -Be $true

            Import-Module $script:RegistryModulePath -DisableNameChecking -Force
            Import-Module $script:LoaderModulePath -DisableNameChecking -Force
            Import-Module $script:DispatcherModulePath -DisableNameChecking -Force

            Get-Command Register-FragmentCommand -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Load-FragmentForCommand -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
            Get-Command Register-CommandDispatcher -ErrorAction SilentlyContinue | Should -Not -BeNullOrEmpty
        }
    }

    Context 'FunctionRegistration registry wiring' {
        BeforeEach {
            $script:Suffix = "CmdAccess_$([Guid]::NewGuid().ToString('N').Substring(0, 8))"
            $script:FuncName = "IntegrationFunc_$script:Suffix"
            $global:RegisteredCommands = [System.Collections.Generic.List[string]]::new()
        }

        AfterEach {
            Remove-Item -Path "Function:\$script:FuncName" -Force -ErrorAction SilentlyContinue
            Remove-Variable -Name CurrentFragmentContext -Scope Global -ErrorAction SilentlyContinue
            Remove-Variable -Name RegisteredCommands -Scope Global -ErrorAction SilentlyContinue

            if (Test-Path -LiteralPath $script:RegistryModulePath) {
                Import-Module $script:RegistryModulePath -DisableNameChecking -Force
            }

            if (Test-Path -LiteralPath $script:LoaderModulePath) {
                Import-Module $script:LoaderModulePath -DisableNameChecking -Force
            }
        }

        It 'Registers commands through Set-AgentModeFunction when a registry stub is available' {
            $global:RegisteredCommands = [System.Collections.Generic.List[string]]::new()
            $registerStub = {
                param(
                    [string]$CommandName,
                    [string]$FragmentName,
                    [string]$CommandType
                )
                $global:RegisteredCommands.Add("${CommandType}:${CommandName}->${FragmentName}")
                return $true
            }.GetNewClosure()

            Set-Item -Path 'Function:\Register-FragmentCommand' -Value $registerStub -Force

            $global:CurrentFragmentContext = 'integration-fragment'
            Set-AgentModeFunction -Name $script:FuncName -Body { 'registered' } | Should -Be $true
            $global:RegisteredCommands | Should -Contain "Function:$($script:FuncName)->integration-fragment"
        }

        It 'Invokes a proxy that loads its fragment before executing the real command' {
            $script:ProxyLoads = 0
            $realName = "IntegrationReal_$script:Suffix"

            function global:Load-FragmentForCommand {
                param([string]$CommandName)
                $script:ProxyLoads++
                [void]$global:AgentModeReplaceAllowed.Add($CommandName)
                Set-AgentModeFunction -Name $CommandName -Body { 'proxy-loaded' } | Out-Null
                return $true
            }

            function global:Get-FragmentForCommand {
                param([string]$CommandName)
                return 'integration-fragment'
            }

            New-FragmentCommandProxy -CommandName $realName -FragmentName 'integration-fragment' |
                Should -Be $true

            & $realName | Should -Be 'proxy-loaded'
            $script:ProxyLoads | Should -Be 1
        }

        It 'Defers expensive setup through Register-LazyFunction' {
            $lazyName = "IntegrationLazy_$script:Suffix"
            $script:InitializerRuns = 0

            Register-LazyFunction -Name $lazyName -Initializer {
                $script:InitializerRuns++
                Set-AgentModeFunction -Name $lazyName -Body { 'lazy-ready' } | Out-Null
            } | Should -Be $true

            $script:InitializerRuns | Should -Be 0
            & $lazyName | Should -Be 'lazy-ready'
            $script:InitializerRuns | Should -Be 1
        }
    }
}
