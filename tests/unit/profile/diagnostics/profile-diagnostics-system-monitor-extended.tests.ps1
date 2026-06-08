<#
tests/unit/profile-diagnostics-system-monitor-extended.tests.ps1
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
    $script:TestRepoRoot = Get-TestRepoRoot -StartPath $PSScriptRoot
    $script:Fragment = Join-Path $script:TestRepoRoot 'profile.d/diagnostics-modules/monitoring/diagnostics-system-monitor.ps1'
}
Describe 'profile.d/diagnostics-modules/monitoring/diagnostics-system-monitor.ps1 extended scenarios' {
    It 'Documents system monitoring diagnostic functions' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'System monitoring diagnostic functions'
        $c | Should -Match 'CPU, memory, disk, and network monitoring'
    }
    It 'Defines cross-platform Get-XPlat helpers for CPU memory and disk' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Get-XPlatCpuInfo'
        $c | Should -Match 'Get-XPlatMemoryInfo'
        $c | Should -Match 'Get-XPlatDiskInfo'
    }
    It 'Registers sysinfo sysstat and cpuinfo aliases' {
        $c = Get-Content -LiteralPath $script:Fragment -Raw
        $c | Should -Match 'Show-SystemDashboard'
        $c | Should -Match 'sysinfo'
        $c | Should -Match 'cpuinfo'
    }
}
