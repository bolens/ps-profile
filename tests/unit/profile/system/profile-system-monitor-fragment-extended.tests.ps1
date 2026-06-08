# ===============================================
# profile-system-monitor-fragment-extended.tests.ps1
# Execution tests for system-monitor.ps1 fragment behavior
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

function script:Reset-SystemMonitorFragmentState {
    Remove-Variable -Name 'SystemMonitorLoaded' -Scope Global -ErrorAction SilentlyContinue
}

Describe 'profile.d/system-monitor.ps1 extended scenarios' {
    BeforeEach {
        Reset-SystemMonitorFragmentState
    }

    It 'Loads system monitor commands from diagnostics-system-monitor module' {
        . (Join-Path $script:ProfileDir 'system-monitor.ps1')

        Get-Command Show-SystemDashboard -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Show-SystemStatus -ErrorAction Stop | Should -Not -BeNullOrEmpty
        (Get-Variable -Name 'SystemMonitorLoaded' -Scope Global -ErrorAction Stop).Value | Should -Be $true
    }

    It 'Show-SystemStatus executes without throwing' {
        . (Join-Path $script:ProfileDir 'system-monitor.ps1')

        { Show-SystemStatus } | Should -Not -Throw
    }

    It 'Skips re-initialization when system monitor helpers are already loaded' {
        . (Join-Path $script:ProfileDir 'system-monitor.ps1')
        $firstStatus = Get-Command Show-SystemStatus -ErrorAction Stop

        . (Join-Path $script:ProfileDir 'system-monitor.ps1')

        (Get-Command Show-SystemStatus -ErrorAction Stop).ScriptBlock.ToString() |
            Should -Be $firstStatus.ScriptBlock.ToString()
    }
}
