<#
tests/unit/profile-package-manager-base-extended.tests.ps1

.SYNOPSIS
    Extended unit tests for PackageManagerBase registration helpers.
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
    $script:BootstrapDir = Get-TestPath -RelativePath 'profile.d\bootstrap' -StartPath $PSScriptRoot -EnsureExists
    foreach ($bootstrapFile in @(
            'GlobalState.ps1'
            'CommandCache.ps1'
            'MissingToolWarnings.ps1'
            'FunctionRegistration.ps1'
        )) {
        . (Join-Path $script:BootstrapDir $bootstrapFile)
    }

    . (Join-Path $script:BootstrapDir 'PackageManagerBase.ps1')
}

Describe 'PackageManagerBase extended scenarios' {
    BeforeEach {
        $suffix = Get-Random
        $global:TestPkgMgrManagerName = "ExtendedPkgMgr$suffix"
        $global:TestPkgMgrCommandName = "extendedpkgcmd$suffix"
        $global:TestPkgMgrCustomCommandName = "ExtendedAudit$suffix"
    }

    AfterEach {
        Remove-Item -Path "Function:\global:Invoke-$($global:TestPkgMgrManagerName)" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:Install-$($global:TestPkgMgrManagerName)Package" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$($global:TestPkgMgrCustomCommandName)" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$($global:TestPkgMgrCommandName)" -Force -ErrorAction SilentlyContinue
    }

    Context 'Register-PackageManager' {
        It 'Rejects blank manager names at parameter binding time' {
            { Register-PackageManager -ManagerName '' -CommandName 'npm' } | Should -Throw
            { Register-PackageManager -ManagerName 'Npm' -CommandName '' } | Should -Throw
        }

        It 'Registers standard package manager command functions' {
            $registered = Register-PackageManager `
                -ManagerName $global:TestPkgMgrManagerName `
                -CommandName $global:TestPkgMgrCommandName `
                -GlobalFlag '-g'
            [bool]$registered | Should -Be $true

            Get-Command -Name "Install-$($global:TestPkgMgrManagerName)Package" -ErrorAction Stop | Should -Not -BeNullOrEmpty
            Get-Command -Name "Invoke-$($global:TestPkgMgrManagerName)" -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }

        It 'Registers custom command handlers from CustomCommands' {
            $registered = Register-PackageManager `
                -ManagerName $global:TestPkgMgrManagerName `
                -CommandName $global:TestPkgMgrCommandName `
                -CustomCommands @{
                    $global:TestPkgMgrCustomCommandName = { 'audit-result' }
                }
            [bool]$registered | Should -Be $true

            Get-Command -Name $global:TestPkgMgrCustomCommandName -ErrorAction Stop | Should -Not -BeNullOrEmpty
            & $global:TestPkgMgrCustomCommandName | Should -Be 'audit-result'
        }

        It 'Registers list and update helpers alongside install' {
            $managerName = $global:TestPkgMgrManagerName
            $commandName = $global:TestPkgMgrCommandName

            $registered = Register-PackageManager -ManagerName $managerName -CommandName $commandName
            [bool]$registered | Should -Be $true

            Get-Command -Name "Get-${managerName}Packages" -ErrorAction Stop | Should -Not -BeNullOrEmpty
            Get-Command -Name "Update-${managerName}Packages" -ErrorAction Stop | Should -Not -BeNullOrEmpty
            Get-Command -Name "Remove-${managerName}Package" -ErrorAction Stop | Should -Not -BeNullOrEmpty
        }

        It 'Accepts optional lock file metadata during registration' {
            $managerName = $global:TestPkgMgrManagerName
            $commandName = $global:TestPkgMgrCommandName

            $registered = Register-PackageManager `
                -ManagerName $managerName `
                -CommandName $commandName `
                -LockFile 'package-lock.json'
            [bool]$registered | Should -Be $true
        }
    }
}
