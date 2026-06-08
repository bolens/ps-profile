<#
tests/unit/profile-assumed-commands-env-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for assumed command environment initialization patterns.
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

Describe 'AssumedCommands environment extended scenarios' {
    BeforeEach {
        if ($global:AssumedAvailableCommands) {
            $global:AssumedAvailableCommands.Clear()
        }
    }

    Context 'Environment token parsing pattern' {
        It 'Registers comma-separated command names like startup parsing does' {
            $tokens = 'alpha-cli,beta-cli' -split '[,;\s]+' |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

            Add-AssumedCommand -Name $tokens | Should -Be $true

            [string[]](Get-AssumedCommands) | Should -Contain 'alpha-cli'
            [string[]](Get-AssumedCommands) | Should -Contain 'beta-cli'
        }

        It 'Registers semicolon and whitespace separated command names' {
            $tokens = 'one-cli;two-cli three-cli' -split '[,;\s]+' |
                Where-Object { -not [string]::IsNullOrWhiteSpace($_) }

            Add-AssumedCommand -Name $tokens | Out-Null

            [string[]](Get-AssumedCommands) | Should -Contain 'one-cli'
            [string[]](Get-AssumedCommands) | Should -Contain 'two-cli'
            [string[]](Get-AssumedCommands) | Should -Contain 'three-cli'
        }

        It 'Returns a string array from Get-AssumedCommands even for a single entry' {
            Add-AssumedCommand -Name 'solo-cli' | Out-Null

            $commands = @(Get-AssumedCommands)
            $commands | Should -BeOfType [string[]]
            $commands.Count | Should -Be 1
            $commands[0] | Should -Be 'solo-cli'
        }
    }

    Context 'Remove-AssumedCommand cleanup' {
        It 'Removes only the requested commands from the registry' {
            Add-AssumedCommand -Name @('keep-cli', 'drop-cli') | Out-Null

            Remove-AssumedCommand -Name 'drop-cli' | Should -Be $true

            [string[]](Get-AssumedCommands) | Should -Contain 'keep-cli'
            [string[]](Get-AssumedCommands) | Should -Not -Contain 'drop-cli'
        }

        It 'Skips blank entries without failing the removal call' {
            Add-AssumedCommand -Name 'temp-cli' | Out-Null

            Remove-AssumedCommand -Name @('temp-cli', '   ') | Should -Be $true
            [string[]](Get-AssumedCommands) | Should -Not -Contain 'temp-cli'
        }
    }
}
