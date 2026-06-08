# ===============================================
# profile-system-fragment-extended.tests.ps1
# Execution tests for system.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'files-module-registry.ps1')
    . (Join-Path $script:ProfileDir 'system.ps1')
}

function script:Reset-SystemFragmentState {
    Set-Variable -Name 'SystemInitialized' -Scope Global -Value $false -Force
}

Describe 'profile.d/system.ps1 extended scenarios' {
    BeforeEach {
        Reset-SystemFragmentState
    }

    It 'Registers Ensure-System and loads core system utility commands on demand' {
        Get-Command Ensure-System -ErrorAction Stop | Should -Not -BeNullOrEmpty

        Ensure-System

        Get-Command Find-File -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-DiskUsage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Find-String -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Loads system modules from the system subdirectory through the registry' {
        Ensure-System

        $systemModulesDir = Join-Path $script:ProfileDir 'system'
        Test-Path -LiteralPath $systemModulesDir | Should -Be $true
        Get-Command Get-NetworkPorts -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Expand-ArchiveCustom -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Allows repeated Ensure-System calls without losing registered commands' {
        Ensure-System
        Ensure-System

        Get-Command New-EmptyFile -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-TopProcesses -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
