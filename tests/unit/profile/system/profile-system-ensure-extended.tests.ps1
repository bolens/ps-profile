# ===============================================
# profile-system-ensure-extended.tests.ps1
# Execution tests for system.ps1 Ensure-System behavior
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

Describe 'profile.d/system.ps1 Ensure-System extended scenarios' {
    BeforeEach {
        Reset-SystemFragmentState
    }

    It 'Registers Ensure-System and loads modules through the registry' {
        Get-Command Ensure-System -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Load-EnsureModules -ErrorAction Stop | Should -Not -BeNullOrEmpty

        Ensure-System

        Get-Command New-EmptyFile -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-DiskUsage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        $global:SystemInitialized | Should -Be $true
    }

    It 'Ensure-System loads all system subdirectory modules from the registry' {
        Ensure-System

        $registryFiles = $script:FileConversionModuleRegistry['Ensure-System'] | ForEach-Object { $_.File }
        foreach ($moduleFile in $registryFiles) {
            $modulePath = Join-Path $script:ProfileDir 'system' $moduleFile
            Test-Path -LiteralPath $modulePath | Should -Be $true
        }
    }

    It 'Skips re-initialization when system utilities are already loaded' {
        Ensure-System
        $firstFindFile = Get-Command Find-File -ErrorAction Stop

        Ensure-System

        (Get-Command Find-File -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstFindFile.ScriptBlock.ToString()
    }
}
