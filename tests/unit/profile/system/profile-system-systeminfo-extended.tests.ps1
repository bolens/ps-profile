# ===============================================
# profile-system-systeminfo-extended.tests.ps1
# Execution tests for system/SystemInfo.ps1 behavior
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

Describe 'profile.d/system/SystemInfo.ps1 extended scenarios' {
    BeforeEach {
        Reset-SystemFragmentState
        Ensure-System
    }

    It 'Registers system information helpers through Ensure-System' {
        Get-Command Get-CommandInfo -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-DiskUsage -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-TopProcesses -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $whichAlias = Get-Alias which -ErrorAction SilentlyContinue
        if ($whichAlias) {
            $whichAlias.ResolvedCommandName | Should -Be 'Get-CommandInfo'
        }
    }

    It 'Get-CommandInfo resolves built-in commands' {
        $command = Get-CommandInfo Get-Process
        $command | Should -Not -BeNullOrEmpty
        $command.Name | Should -Be 'Get-Process'
    }

    It 'Get-DiskUsage returns filesystem drive information' {
        $usage = @(Get-DiskUsage)
        $usage.Count | Should -BeGreaterThan 0
        $usage[0].PSObject.Properties.Name | Should -Contain 'Name'
    }
}
