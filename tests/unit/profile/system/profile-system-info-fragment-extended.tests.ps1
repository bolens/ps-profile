# ===============================================
# profile-system-info-fragment-extended.tests.ps1
# Execution tests for system-info.ps1 fragment behavior
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
    . (Join-Path $script:ProfileDir 'system-info.ps1')
}

Describe 'profile.d/system-info.ps1 extended scenarios' {
    It 'Registers uptime and battery helpers with aliases' {
        Get-Command Get-SystemUptime -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-BatteryInfo -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command uptime -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command battery -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Get-SystemUptime returns uptime information without throwing' {
        { Get-SystemUptime } | Should -Not -Throw
    }

    It 'Get-BatteryInfo executes without throwing on this platform' {
        { Get-BatteryInfo } | Should -Not -Throw
    }
}
