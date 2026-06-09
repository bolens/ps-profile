<#
tests/unit/profile-package-manager-missing-command-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for package manager helpers when commands are unavailable.
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
    $bootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    foreach ($bootstrapFile in @(
            'GlobalState.ps1'
            'CommandCache.ps1'
            'AssumedCommands.ps1'
            'MissingToolWarnings.ps1'
            'ToolInstallRegistry.ps1'
            'InstallHintResolver.ps1'
            'FunctionRegistration.ps1'
            'PackageManagerBase.ps1'
        )) {
        . (Join-Path $bootstrapDir $bootstrapFile)
    }
}

Describe 'PackageManagerBase missing command extended scenarios' {
    BeforeEach {
        $script:Suffix = Get-Random
        $script:ManagerName = "MissingPkg$script:Suffix"
        $script:CommandName = "missingpkgcmd$script:Suffix"
        Clear-MissingToolWarnings | Out-Null
        $global:CollectedMissingToolWarnings.Clear()
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    AfterEach {
        Remove-Item -Path "Function:\Invoke-$($script:ManagerName)" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Install-$($script:ManagerName)Package" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Get-$($script:ManagerName)Packages" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Update-$($script:ManagerName)Packages" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\Remove-$($script:ManagerName)Package" -Force -ErrorAction SilentlyContinue
        if (Get-Command Clear-TestCommandAvailabilityStub -ErrorAction SilentlyContinue) {
            Clear-TestCommandAvailabilityStub
        }
    }

    Context 'Register-PackageManager missing command handling' {
        It 'Registers invoke, install, list, update, and remove helpers' {
            $null = Register-PackageManager `
                -ManagerName $script:ManagerName `
                -CommandName $script:CommandName

            Get-Command "Invoke-$($script:ManagerName)" -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
            Get-Command "Install-$($script:ManagerName)Package" -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
            Get-Command "Get-$($script:ManagerName)Packages" -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
            Get-Command "Update-$($script:ManagerName)Packages" -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
            Get-Command "Remove-$($script:ManagerName)Package" -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It 'Collects warnings when the invoke wrapper is called without the command' {
            $null = Register-PackageManager `
                -ManagerName $script:ManagerName `
                -CommandName $script:CommandName

            Set-TestCommandAvailabilityState -CommandName $script:CommandName -Available $false
            & "Invoke-$($script:ManagerName)"

            $global:CollectedMissingToolWarnings.Count | Should -BeGreaterThan (0)
            $global:CollectedMissingToolWarnings[0].Tool | Should -Be $script:CommandName
        }

        It 'Registers invoke-script helper alongside standard package commands' {
            $null = Register-PackageManager `
                -ManagerName $script:ManagerName `
                -CommandName $script:CommandName

            Get-Command "Invoke-$($script:ManagerName)Script" -ErrorAction SilentlyContinue |
                Should -Not -BeNullOrEmpty
        }

        It 'Registers custom commands alongside standard helpers' {
            $customName = "Audit$($script:Suffix)"
            $null = Register-PackageManager `
                -ManagerName $script:ManagerName `
                -CommandName $script:CommandName `
                -CustomCommands @{ $customName = { 'audit-ok' } }

                        & $customName | Should -Be 'audit-ok'
        }
        finally {
            Remove-Item -Path "Function:\$customName" -Force -ErrorAction SilentlyContinue
        }

        It 'Returns false when manager metadata is blank' {
            Register-PackageManager -ManagerName '   ' -CommandName $script:CommandName |
                Should -Be $false
        }
    }
}
