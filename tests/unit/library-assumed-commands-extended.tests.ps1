<#
tests/unit/library-assumed-commands-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for assumed command registration helpers.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $bootstrapDir 'GlobalState.ps1')
    . (Join-Path $bootstrapDir 'AssumedCommands.ps1')
}

AfterAll {
    Remove-Item Env:\PS_PROFILE_ASSUME_COMMANDS -ErrorAction SilentlyContinue
    if ($global:AssumedAvailableCommands) {
        $global:AssumedAvailableCommands.Clear()
    }
}

Describe 'AssumedCommands extended scenarios' {
    BeforeEach {
        Remove-Item Env:\PS_PROFILE_ASSUME_COMMANDS -ErrorAction SilentlyContinue
        if ($global:AssumedAvailableCommands) {
            $global:AssumedAvailableCommands.Clear()
        }
    }

    Context 'Add-AssumedCommand' {
        It 'Registers multiple commands in one call' {
            Add-AssumedCommand -Name @('alpha-tool', 'beta-tool') | Should -Be $true

            $commands = [string[]](Get-AssumedCommands)
            $commands | Should -Contain 'alpha-tool'
            $commands | Should -Contain 'beta-tool'
        }

        It 'Rejects empty command names at the parameter binder' {
            { Add-AssumedCommand -Name '' } | Should -Throw
        }

        It 'Treats command names as case-insensitive in the registry' {
            Add-AssumedCommand -Name 'Docker' | Out-Null
            $global:AssumedAvailableCommands.ContainsKey('docker') | Should -Be $true
            $global:AssumedAvailableCommands.ContainsKey('DOCKER') | Should -Be $true
        }
    }

    Context 'Remove-AssumedCommand' {
        It 'Removes previously registered commands' {
            Add-AssumedCommand -Name 'temp-tool' | Out-Null
            Remove-AssumedCommand -Name 'temp-tool' | Should -Be $true
            [string[]](Get-AssumedCommands) | Should -Not -Contain 'temp-tool'
        }

        It 'Returns false when removing unknown commands' {
            Remove-AssumedCommand -Name 'missing-tool' | Should -Be $false
        }
    }
}
