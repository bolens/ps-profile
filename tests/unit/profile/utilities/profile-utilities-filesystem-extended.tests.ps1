# ===============================================
# profile-utilities-filesystem-extended.tests.ps1
# Execution tests for utilities-modules/filesystem/utilities-filesystem.ps1 behavior
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

Describe 'profile.d/utilities-modules/filesystem/utilities-filesystem.ps1 extended scenarios' {
    It 'Registers Open-Explorer through Ensure-Utilities' {
        Get-Command Open-Explorer -ErrorAction Stop | Should -Not -BeNullOrEmpty

        $alias = Get-Alias open-explorer -ErrorAction SilentlyContinue
        if ($alias) {
            $alias.ResolvedCommandName | Should -Be 'Open-Explorer'
        }
    }

    It 'Open-Explorer completes without throwing when file managers are mocked unavailable' {
        if ($IsWindows -or $IsMacOS -or $PSVersionTable.Platform -eq 'Win32NT') {
            Set-ItResult -Inconclusive -Because 'Open-Explorer Linux fallback path is not exercised on this platform'
            return
        }

        foreach ($cmd in @('xdg-open', 'nautilus', 'dolphin', 'thunar')) {
            Set-TestCommandAvailabilityState -CommandName $cmd -Available $false
        }
        if (Get-Command Clear-TestCachedCommandCache -ErrorAction SilentlyContinue) {
            Clear-TestCachedCommandCache | Out-Null
        }

        { Open-Explorer -ErrorAction SilentlyContinue | Out-Null } | Should -Not -Throw
    }

    It 'Allows repeated Ensure-Utilities calls without losing Open-Explorer' {
        Ensure-Utilities
        Ensure-Utilities

        Get-Command Open-Explorer -ErrorAction Stop | Should -Not -BeNullOrEmpty
    }
}
