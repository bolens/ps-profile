<#
tests/unit/profile-cloud-provider-missing-warning-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for Invoke-CloudMissingToolWarning composition.
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

    . (Join-Path $bootstrapDir 'CloudProviderBase.ps1')
}

Describe 'Invoke-CloudMissingToolWarning extended scenarios' {
    BeforeEach {
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
    }

    Context 'Invoke-CloudMissingToolWarning' {
        It 'Uses an explicit InstallHint when one is provided' {
            Invoke-CloudMissingToolWarning `
                -CommandName 'aws' `
                -InstallHint 'Install AWS CLI from your package manager'

            $global:CollectedMissingToolWarnings.Count | Should -Be 1
            $global:CollectedMissingToolWarnings[0].InstallHint |
                Should -Be 'Install AWS CLI from your package manager'
        }

        It 'Collects platform hints through Invoke-MissingToolWarning when no InstallHint is supplied' {
            Invoke-CloudMissingToolWarning -CommandName 'aws'

            $global:CollectedMissingToolWarnings.Count | Should -Be 1
            $global:CollectedMissingToolWarnings[0].Tool | Should -Be 'aws'
            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'Install'
        }

        It 'Forwards InstallPackageName to Invoke-MissingToolWarning' {
            Invoke-CloudMissingToolWarning `
                -CommandName 'az' `
                -InstallPackageName 'azure-cli'

            $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'azure-cli'
        }

        It 'Falls back to Resolve-CloudInstallHint when Invoke-MissingToolWarning is unavailable' {
            $originalInvoke = Get-Command Invoke-MissingToolWarning -ErrorAction SilentlyContinue
            Remove-Item Function:\Invoke-MissingToolWarning -Force -ErrorAction SilentlyContinue
            Remove-Item Function:\global:Invoke-MissingToolWarning -Force -ErrorAction SilentlyContinue

            try {
                Invoke-CloudMissingToolWarning -CommandName 'gcloud' -InstallPackageName 'gcloud-sdk'

                $global:CollectedMissingToolWarnings[0].InstallHint | Should -Match 'gcloud-sdk'
            }
            finally {
                if ($null -ne $originalInvoke) {
                    Set-Item -Path Function:\global:Invoke-MissingToolWarning -Value $originalInvoke.ScriptBlock -Force
                }
            }
        }
    }

    Context 'Invoke-CloudCommand' {
        BeforeEach {
            if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
                Clear-TestCommandAvailabilityStub
            }
        }

        AfterEach {
            if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
                Clear-TestCommandAvailabilityStub
            }
        }

        It 'Returns null and collects a warning when the cloud command is unavailable' {
            Set-TestCommandAvailabilityState -CommandName 'aws' -Available $false

            Invoke-CloudCommand -CommandName 'aws' -Arguments @('sts', 'get-caller-identity') |
                Should -BeNullOrEmpty

            $global:CollectedMissingToolWarnings.Count | Should -BeGreaterThan (0)
        }
    }
}
