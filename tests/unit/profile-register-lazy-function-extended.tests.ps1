<#
tests/unit/profile-register-lazy-function-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Register-LazyFunction deferred initialization.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'FunctionRegistration.ps1')
}

Describe 'Register-LazyFunction extended scenarios' {
    BeforeEach {
        $script:Suffix = Get-Random
        $script:LazyName = "LazyExtended_$script:Suffix"
        $script:AliasName = "LazyAlias_$script:Suffix"
    }

    AfterEach {
        Remove-Item -Path "Function:\$script:LazyName" -Force -ErrorAction SilentlyContinue
        Remove-Item Alias:\$script:AliasName -Force -ErrorAction SilentlyContinue
    }

    Context 'Register-LazyFunction' {
        It 'Registers an optional alias that forwards to the lazy stub' {
            $lazyName = $script:LazyName
            Register-LazyFunction -Name $lazyName -Alias $script:AliasName -Initializer {
                Set-AgentModeFunction -Name $lazyName -Body { 'alias-ready' } | Out-Null
            } | Should -Be $true

            & $script:AliasName | Should -Be 'alias-ready'
        }

        It 'Returns false when the function name already exists' {
            Set-AgentModeFunction -Name $script:LazyName -Body { 'existing' } | Out-Null

            Register-LazyFunction -Name $script:LazyName -Initializer {
                Set-AgentModeFunction -Name $using:LazyName -Body { 'replacement' } | Out-Null
            } | Should -Be $false
        }

        It 'Registers the lazy name in AgentModeReplaceAllowed for initializer replacement' {
            Register-LazyFunction -Name $script:LazyName -Initializer {
                Set-AgentModeFunction -Name $script:LazyName -Body { 'ready' } | Out-Null
            } | Should -Be $true

            $global:AgentModeReplaceAllowed.Contains($script:LazyName) | Should -Be $true
        }

        It 'Runs the initializer only once across repeated invocations' {
            $script:InitCount = 0
            $lazyName = $script:LazyName
            Register-LazyFunction -Name $lazyName -Initializer {
                $script:InitCount++
                Set-AgentModeFunction -Name $lazyName -Body { 'ready' } | Out-Null
            } | Out-Null

            & $lazyName | Should -Be 'ready'
            & $lazyName | Should -Be 'ready'
            $script:InitCount | Should -Be 1
        }

        It 'Returns false for a whitespace-only function name' {
            Register-LazyFunction -Name '   ' -Initializer { } | Should -Be $false
        }
    }
}
