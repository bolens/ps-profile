<#
tests/unit/library-fragment-command-registry-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FragmentCommandRegistry edge cases and bulk helpers.
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
    $script:RegistryModulePath = Join-Path $script:RepoRoot 'scripts' 'lib' 'fragment' 'FragmentCommandRegistry.psm1'
    Import-Module $script:RegistryModulePath -DisableNameChecking -Force
    $script:TempRoot = New-TestTempDirectory -Prefix 'FragmentRegistryExtended'
}

AfterAll {
    Remove-Module FragmentCommandRegistry -ErrorAction SilentlyContinue -Force
    Remove-Item Function:\New-FragmentCommandProxy -ErrorAction SilentlyContinue -Force

    if ($script:TempRoot -and (Test-Path -LiteralPath $script:TempRoot)) {
        Remove-Item -LiteralPath $script:TempRoot -Recurse -Force -ErrorAction SilentlyContinue
    }
}

Describe 'FragmentCommandRegistry extended scenarios' {
    BeforeEach {
        Initialize-FragmentCommandRegistry
        $global:FragmentCommandRegistry.Clear()
    }

    Context 'Register-FragmentCommand type normalization' {
        It 'Accepts FragmentCommandType enum values' {
            InModuleScope -ModuleName FragmentCommandRegistry {
                Register-FragmentCommand -CommandName 'EnumCmd' -FragmentName 'test' -CommandType ([FragmentCommandType]::Function) |
                    Should -Be $true
                $global:FragmentCommandRegistry['EnumCmd'].Type | Should -Be 'Function'
            }
        }

        It 'Returns false when CommandType normalizes to empty string' {
            Register-FragmentCommand -CommandName 'EmptyType' -FragmentName 'test' -CommandType '' |
                Should -Be $false
            Register-FragmentCommand -CommandName 'WhitespaceType' -FragmentName 'test' -CommandType '   ' |
                Should -Be $false
        }
    }

    Context 'Registry lookup edge cases' {
        It 'Returns null when registry entry exists but value is null' {
            $global:FragmentCommandRegistry['NullEntry'] = $null

            Get-FragmentForCommand -CommandName 'NullEntry' | Should -BeNullOrEmpty
            Get-CommandRegistryInfo -CommandName 'NullEntry' | Should -BeNullOrEmpty
        }

        It 'Returns null for empty command names in Get-CommandRegistryInfo' {
            Get-CommandRegistryInfo -CommandName '' | Should -BeNullOrEmpty
            Get-CommandRegistryInfo -CommandName $null | Should -BeNullOrEmpty
        }
    }

    Context 'Import-CommandRegistry' {
        It 'Returns false for empty or whitespace JSON' {
            Import-CommandRegistry -Json '' | Should -Be $false
            Import-CommandRegistry -Json '   ' | Should -Be $false
        }
    }

    Context 'Register-CommandsFromFragment AST parsing' {
        It 'Registers functions discovered through AST parsing when helpers are available' {
            $fragmentPath = Join-Path $script:TempRoot 'ast-fragment.ps1'
            @'
function Get-AstFragmentHelper {
    return 'ok'
}
'@ | Set-Content -LiteralPath $fragmentPath -Encoding UTF8

            $libPath = Join-Path $script:RepoRoot 'scripts' 'lib'
            Import-Module (Join-Path $libPath 'code-analysis' 'AstParsing.psm1') -DisableNameChecking -Force -ErrorAction SilentlyContinue

            $count = Register-CommandsFromFragment -FragmentPath $fragmentPath -FragmentName 'ast-test'
            $count | Should -BeGreaterThan 0
            Test-CommandInRegistry -CommandName 'Get-AstFragmentHelper' | Should -Be $true
        }
    }

    Context 'Register-CommandsFromFragment' {
        It 'Registers aliases discovered through regex parsing' {
            $fragmentPath = Join-Path $script:TempRoot 'alias-fragment.ps1'
            @'
Set-AgentModeAlias -Name 'extalias' -Target 'Get-ChildItem'
'@ | Set-Content -LiteralPath $fragmentPath -Encoding UTF8

            $count = Register-CommandsFromFragment -FragmentPath $fragmentPath -FragmentName 'alias-test'
            $count | Should -BeGreaterThan 0
            Test-CommandInRegistry -CommandName 'extalias' | Should -Be $true
        }

        It 'Skips commands that are already registered' {
            $fragmentPath = Join-Path $script:TempRoot 'duplicate-fragment.ps1'
            @'
Set-AgentModeFunction -Name 'dupfunc' -Body { }
'@ | Set-Content -LiteralPath $fragmentPath -Encoding UTF8

            Register-FragmentCommand -CommandName 'dupfunc' -FragmentName 'existing' -CommandType 'Function' | Out-Null
            $count = Register-CommandsFromFragment -FragmentPath $fragmentPath -FragmentName 'duplicate-test'

            $count | Should -Be 0
            Get-FragmentForCommand -CommandName 'dupfunc' | Should -Be 'existing'
        }

        It 'Handles unreadable fragment paths without throwing' {
            $missingPath = Join-Path $script:TempRoot 'missing-fragment.ps1'
            { Register-CommandsFromFragment -FragmentPath $missingPath -FragmentName 'missing' } | Should -Not -Throw
            Register-CommandsFromFragment -FragmentPath $missingPath -FragmentName 'missing' | Should -Be 0
        }
    }

    Context 'Create-CommandProxiesForAutocomplete' {
        It 'Returns zero totals when New-FragmentCommandProxy is unavailable' {
            Remove-Item Function:\New-FragmentCommandProxy -ErrorAction SilentlyContinue -Force

            $fragmentPath = Join-Path $script:RepoRoot 'profile.d' 'scoop.ps1'
            $fragmentFile = Get-Item -LiteralPath $fragmentPath
            $result = Create-CommandProxiesForAutocomplete -FragmentFiles @($fragmentFile)

            $result.TotalCommands | Should -Be 0
            $result.CreatedProxies | Should -Be 0
            $result.FailedProxies | Should -Be 0
        }

        It 'Creates proxies for registered commands when proxy helper exists' {
            function global:New-FragmentCommandProxy {
                param([string]$CommandName, [string]$FragmentName)
                return $true
            }

            Register-FragmentCommand -CommandName 'ProxyCmd' -FragmentName 'proxy-fragment' -CommandType 'Function' | Out-Null
            $fragmentFile = [System.IO.FileInfo]::new((Join-Path $script:TempRoot 'proxy-fragment.ps1'))
            New-Item -ItemType File -Path $fragmentFile.FullName -Force | Out-Null

            $result = Create-CommandProxiesForAutocomplete -FragmentFiles @($fragmentFile)
            $result.TotalCommands | Should -BeGreaterThan 0
            $result.CreatedProxies | Should -BeGreaterThan 0
            $result.FailedProxies | Should -Be 0
        }

        It 'Counts failed proxies when proxy helper returns false' {
            function global:New-FragmentCommandProxy {
                param([string]$CommandName, [string]$FragmentName)
                return $false
            }

            Register-FragmentCommand -CommandName 'FailProxy' -FragmentName 'fail-fragment' -CommandType 'Function' | Out-Null
            $fragmentFile = [System.IO.FileInfo]::new((Join-Path $script:TempRoot 'fail-fragment.ps1'))
            New-Item -ItemType File -Path $fragmentFile.FullName -Force | Out-Null

            $result = Create-CommandProxiesForAutocomplete -FragmentFiles @($fragmentFile)
            $result.FailedProxies | Should -BeGreaterThan 0
        }
    }
}
