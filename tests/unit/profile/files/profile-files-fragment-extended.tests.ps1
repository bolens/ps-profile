# ===============================================
# profile-files-fragment-extended.tests.ps1
# Execution tests for files.ps1 fragment behavior
# ===============================================

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

    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
}

function script:Reset-FilesFragmentState {
    foreach ($flagName in @(
            'FileUtilitiesInitialized'
            'FileConversionDataInitialized'
            'FileConversionDocumentsInitialized'
            'FileConversionMediaInitialized'
            'FileConversionSpecializedInitialized'
            'DevToolsInitialized'
        )) {
        Set-Variable -Name $flagName -Scope Global -Value $false -Force
    }
}

Describe 'profile.d/files.ps1 extended scenarios' {
    BeforeEach {
        Reset-FilesFragmentState
    }

    It 'Registers Ensure-FileUtilities and loads file inspection commands on demand' {
        . (Join-Path $script:ProfileDir 'files.ps1')

        Get-Command Ensure-FileUtilities -ErrorAction Stop | Should -Not -BeNullOrEmpty

        Ensure-FileUtilities

        Get-Command Get-FileHashValue -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-FileHead -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Routes Write-SubModuleError through Write-ProfileError when debug is enabled' {
        . (Join-Path $script:ProfileDir 'files.ps1')

        $previousDebug = $env:PS_PROFILE_DEBUG
        $script:capturedErrors = [System.Collections.Generic.List[System.Management.Automation.ErrorRecord]]::new()

        try {
            $env:PS_PROFILE_DEBUG = '1'
            if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
                Clear-TestCachedCommandCache | Out-Null
            }

            Set-Item -Path Function:\global:Write-ProfileError -Value {
                param(
                    [Parameter(Mandatory)]
                    [System.Management.Automation.ErrorRecord]$ErrorRecord,
                    [string]$Context = '',
                    [string]$Category = 'Profile'
                )

                if ($ErrorRecord -is [System.Management.Automation.ErrorRecord]) {
                    $script:capturedErrors.Add($ErrorRecord) | Out-Null
                }
            } -Force

                        throw 'files fragment submodule failure'
        }
        catch {
            Write-SubModuleError -ErrorRecord $_ -ModuleName 'test-module.ps1'

            $script:capturedErrors.Count | Should -Be 1
            $script:capturedErrors[0].Exception.Message | Should -Be 'files fragment submodule failure'
        }
        finally {
            $env:PS_PROFILE_DEBUG = $previousDebug
            Remove-Item -Path Function:\global:Write-ProfileError -Force -ErrorAction SilentlyContinue
        }
    }

    It 'Allows repeated Ensure-FileUtilities calls without losing registered commands' {
        . (Join-Path $script:ProfileDir 'files.ps1')

        Ensure-FileUtilities
        Ensure-FileUtilities

        Get-Command Get-FileSize -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-HexDump -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
