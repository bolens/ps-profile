<#
tests/unit/profile-install-hint-warnings-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for container and dangerzone missing-tool warnings.
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
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

Describe 'Install hint warning extended scenarios' {
    BeforeEach {
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
    }

    Context 'Invoke-ContainerEngineMissingWarning' {
        It 'Collects a combined docker and podman warning' {
            Invoke-ContainerEngineMissingWarning

            $global:CollectedMissingToolWarnings.Count | Should -Be 1
            $global:CollectedMissingToolWarnings[0].Tool | Should -Be 'docker/podman'
            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'docker'
            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'podman'
        }

        It 'Honors a custom tool display name' {
            Invoke-ContainerEngineMissingWarning -Tool 'container-runtime'

            $global:CollectedMissingToolWarnings[0].Tool | Should -Be 'container-runtime'
        }
    }

    Context 'Invoke-DangerzoneMissingWarning' {
        It 'Collects a dangerzone warning entry' {
            Invoke-DangerzoneMissingWarning

            $global:CollectedMissingToolWarnings.Count | Should -Be 1
            $global:CollectedMissingToolWarnings[0].Tool | Should -Be 'dangerzone'
            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'Install'
        }

        It 'Appends Docker requirement text when the hint does not mention Docker' {
            $originalHint = Get-Command Get-PlatformInstallHint -ErrorAction SilentlyContinue
            function global:Get-PlatformInstallHint { return 'Install with: scoop install dangerzone' }

            try {
                Clear-MissingToolWarnings | Out-Null
                $global:CollectedMissingToolWarnings.Clear()
                Invoke-DangerzoneMissingWarning

                $hint = $global:CollectedMissingToolWarnings[0].InstallHint
                $hint | Should -Match 'requires Docker'
            }
            finally {
                Remove-Item Function:\Get-PlatformInstallHint -Force -ErrorAction SilentlyContinue
                if ($null -ne $originalHint) {
                    Set-Item -Path Function:\global:Get-PlatformInstallHint -Value $originalHint.ScriptBlock -Force
                }
            }
        }
    }

    Context 'Invoke-CommandMissingToolWarning' {
        It 'Uses DefaultInstallCommand when Invoke-MissingToolWarning is unavailable' {
            $originalInvoke = Get-Command Invoke-MissingToolWarning -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-MissingToolWarning -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Invoke-MissingToolWarning -Force -ErrorAction SilentlyContinue

            try {
                Invoke-CommandMissingToolWarning `
                    -CommandName 'custom-cli' `
                    -DefaultInstallCommand 'scoop install custom-cli'

                $global:CollectedMissingToolWarnings[0].InstallHint |
                    Should -Match 'scoop install custom-cli'
            }
            finally {
                if ($null -ne $originalInvoke) {
                    Set-Item -Path Function:\global:Invoke-MissingToolWarning -Value $originalInvoke.ScriptBlock -Force
                }
            }
        }
    }
}
