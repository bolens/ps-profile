<#
tests/unit/profile-function-registration-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for FunctionRegistration bootstrap helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'FunctionRegistration.ps1')
}

Describe 'FunctionRegistration extended scenarios' {
    BeforeAll {
        $script:LazyName = $null
    }

    BeforeEach {
        $script:Suffix = Get-Random
        $script:FuncName = "ExtendedFunc_$script:Suffix"
        $script:AliasName = "ExtendedAlias_$script:Suffix"
        $script:TargetName = "ExtendedTarget_$script:Suffix"
        $script:LazyName = $null
    }

    AfterEach {
        Remove-Item -Path "Function:\global:$script:FuncName" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$script:TargetName" -Force -ErrorAction SilentlyContinue
        Remove-Item Alias:\global:$script:AliasName -Force -ErrorAction SilentlyContinue
        if ($null -ne $script:LazyName) {
            Remove-Item -Path "Function:\global:$script:LazyName" -Force -ErrorAction SilentlyContinue
        }
    }

    Context 'Set-AgentModeFunction' {
        It 'Returns the created script block when ReturnScriptBlock is specified' {
            $block = Set-AgentModeFunction -Name $script:FuncName -Body { 'extended-body' } -ReturnScriptBlock
            $block | Should -BeOfType [scriptblock]
            & $script:FuncName | Should -Be 'extended-body'
        }

        It 'Returns false when the function name is already registered' {
            Set-AgentModeFunction -Name $script:FuncName -Body { 'first' } | Should -Be $true
            Set-AgentModeFunction -Name $script:FuncName -Body { 'second' } | Should -Be $false
            & $script:FuncName | Should -Be 'first'
        }

        It 'Allows replacement when the name is on the replace allow-list' {
            Set-AgentModeFunction -Name $script:FuncName -Body { 'original' } | Should -Be $true
            $global:AgentModeReplaceAllowed.Add($script:FuncName) | Out-Null

            Set-AgentModeFunction -Name $script:FuncName -Body { 'replaced' } | Should -Be $true
            & $script:FuncName | Should -Be 'replaced'
        }
    }

    Context 'Set-AgentModeAlias' {
        It 'Returns alias definition text when ReturnDefinition is specified' {
            Set-AgentModeFunction -Name $script:TargetName -Body { 'target' } | Out-Null

            $definition = Set-AgentModeAlias -Name $script:AliasName -Target $script:TargetName -ReturnDefinition
            $definition | Should -Match $script:AliasName
            $definition | Should -Match $script:TargetName
        }

        It 'Returns false when the alias already exists' {
            Set-AgentModeFunction -Name $script:TargetName -Body { 'target' } | Out-Null
            Set-AgentModeAlias -Name $script:AliasName -Target $script:TargetName | Should -Be $true
            Set-AgentModeAlias -Name $script:AliasName -Target $script:TargetName | Should -Be $false
        }
    }

    Context 'Register-LazyFunction' {
        It 'Defers initializer execution until the stub is invoked' {
            $script:LazyName = "ExtendedLazy_$script:Suffix"
            $global:ExtendedLazyInitializerRan = $false
            $lazyName = $script:LazyName

            Register-LazyFunction -Name $lazyName -Initializer {
                $global:ExtendedLazyInitializerRan = $true
                Set-AgentModeFunction -Name $lazyName -Body { 'lazy-ready' } | Out-Null
            } | Should -Be $true

            $global:ExtendedLazyInitializerRan | Should -Be $false
            & $lazyName | Should -Be 'lazy-ready'
            $global:ExtendedLazyInitializerRan | Should -Be $true
        }
    }
}
