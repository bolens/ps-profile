<#
tests/unit/profile-tool-wrapper-install-package-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Register-ToolWrapper install package resolution.
#>

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')

    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    foreach ($bootstrapFile in @(
            'GlobalState.ps1'
            'CommandCache.ps1'
            'AssumedCommands.ps1'
            'MissingToolWarnings.ps1'
            'ToolInstallRegistry.ps1'
            'InstallHintResolver.ps1'
            'FunctionRegistration.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

Describe 'Register-ToolWrapper install package extended scenarios' {
    BeforeEach {
        $script:Suffix = Get-Random
        $script:WrapperName = "WrapperPkg_$script:Suffix"
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
    }

    AfterEach {
        Remove-Item -Path "Function:\$script:WrapperName" -Force -ErrorAction SilentlyContinue
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    Context 'Register-ToolWrapper' {
        It 'Uses InstallPackageName when emitting Invoke-MissingToolWarning for missing commands' {
            $missingCommand = "missing-wrapper-cmd-$script:Suffix"
            Set-TestCommandAvailabilityState -CommandName $missingCommand -Available $false

            Register-ToolWrapper -FunctionName $script:WrapperName -CommandName $missingCommand -InstallPackageName 'ripgrep' |
                Should -Be $true

            & $script:WrapperName

            $global:CollectedMissingToolWarnings.Count | Should -Be 1
            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'ripgrep'
        }

        It 'Uses a custom WarningMessage instead of install hint resolution' {
            $missingCommand = "missing-warning-cmd-$script:Suffix"
            Set-TestCommandAvailabilityState -CommandName $missingCommand -Available $false

            Register-ToolWrapper `
                -FunctionName $script:WrapperName `
                -CommandName $missingCommand `
                -WarningMessage 'Custom wrapper warning' | Out-Null

            $warnings = @( & $script:WrapperName 3>&1 )
            ($warnings -join ' ') | Should -Match 'Custom wrapper warning'
            $global:CollectedMissingToolWarnings.Count | Should -Be 0
        }

        It 'Executes the wrapped command when it is available' {
            Register-ToolWrapper -FunctionName $script:WrapperName -CommandName 'Write-Output' -CommandType Cmdlet |
                Should -Be $true

            & $script:WrapperName 'wrapper-ok' | Should -Be 'wrapper-ok'
        }

        It 'Forwards remaining arguments to the wrapped command' {
            Register-ToolWrapper -FunctionName $script:WrapperName -CommandName 'Write-Output' -CommandType Cmdlet |
                Out-Null

            & $script:WrapperName 'one' 'two' | Should -Be @('one', 'two')
        }

        It 'Returns false when the wrapper function name already exists' {
            Set-AgentModeFunction -Name $script:WrapperName -Body { 'existing' } | Out-Null

            Register-ToolWrapper -FunctionName $script:WrapperName -CommandName 'Write-Output' |
                Should -Be $false
        }
    }
}
