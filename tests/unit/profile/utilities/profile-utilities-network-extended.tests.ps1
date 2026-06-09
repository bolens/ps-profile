# ===============================================
# profile-utilities-network-extended.tests.ps1
# Execution tests for utilities-modules/network/utilities-network.ps1 behavior
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
    . (Join-Path $script:ProfileDir 'utilities.ps1')
    Ensure-Utilities
}

Describe 'profile.d/utilities-modules/network/utilities-network.ps1 extended scenarios' {
    It 'Registers network helpers through Ensure-Utilities' {
        Get-Command Get-Weather -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Get-MyIP -ErrorAction Stop | Should -Not -BeNullOrEmpty
        Get-Command Start-SpeedTest -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }

    It 'Start-SpeedTest completes without throwing when speedtest binaries are unavailable' {
        foreach ($cmd in @('speedtest', 'speedtest.exe')) {
            Set-TestCommandAvailabilityState -CommandName $cmd -Available $false
        }
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        { Start-SpeedTest -ErrorAction SilentlyContinue | Out-Null } | Should -Not -Throw
    }

    It 'Allows repeated Ensure-Utilities calls without losing network helpers' {
        Ensure-Utilities
        Ensure-Utilities

        Get-Command Get-MyIP -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
