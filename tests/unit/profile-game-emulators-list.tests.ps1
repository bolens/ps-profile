# ===============================================
# profile-game-emulators-list.tests.ps1
# Unit tests for Get-EmulatorList function
# ===============================================

function global:Reset-TestEmulatorCommandAvailability {
    $managedEmulatorCommands = @(
        'dolphin-dev', 'dolphin-nightly', 'dolphin', 'ryujinx-canary', 'ryujinx', 'yuzu',
        'cemu-dev', 'cemu', 'project64', 'mupen64plus', 'lime3ds', 'melonds', 'bsnes',
        'bsnes-hd-beta', 'bsnes-mt', 'snes9x-dev', 'snes9x', 'rpcs3', 'pcsx2-dev', 'pcsx2',
        'duckstation-preview', 'duckstation', 'ppsspp-dev', 'ppsspp', 'vita3k', 'xemu',
        'xenia-canary', 'xenia', 'flycast', 'redream-dev', 'redream', 'retroarch-nightly',
        'retroarch', 'pegasus', 'steam-rom-manager', 'mame'
    )

    Clear-TestCachedCommandCache | Out-Null

    foreach ($command in $managedEmulatorCommands) {
        Remove-Item -Path "Function:\$command" -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "Function:\global:$command" -Force -ErrorAction SilentlyContinue

        if ($global:AssumedAvailableCommands) {
            $removed = $null
            $null = $global:AssumedAvailableCommands.TryRemove($command, [ref]$removed)
        }

        $cacheKey = $command.ToLowerInvariant()
        $global:TestCachedCommandCache[$cacheKey] = [pscustomobject]@{
            Result  = $false
            Expires = (Get-Date).AddHours(24)
        }
    }
}

BeforeAll {
    . (Join-Path $PSScriptRoot '..\TestSupport.ps1')
    $script:ProfileDir = Get-TestPath -RelativePath 'profile.d' -StartPath $PSScriptRoot -EnsureExists
    . (Join-Path $script:ProfileDir 'bootstrap.ps1')
    . (Join-Path $script:ProfileDir 'game-emulators.ps1')
}

Describe 'game-emulators.ps1 - Get-EmulatorList' {
    BeforeEach {
        Reset-TestEmulatorCommandAvailability
    }

    Context 'No emulators available' {
        It 'Returns empty array when no emulators are available' {
            $result = Get-EmulatorList

            @($result).Count | Should -Be 0
        }
    }

    Context 'Some emulators available' {
        It 'Returns list of available emulators' {
            Set-TestCommandAvailabilityState -CommandName 'dolphin-dev'
            Set-TestCommandAvailabilityState -CommandName 'ryujinx-canary'
            Set-TestCommandAvailabilityState -CommandName 'retroarch-nightly'

            $result = Get-EmulatorList

            $result | Should -Not -BeNullOrEmpty
            $result.Count | Should -BeGreaterThan 0

            $dolphin = $result | Where-Object { $_.Name -eq 'Dolphin' }
            $dolphin | Should -Not -BeNullOrEmpty
            $dolphin.Command | Should -Be 'dolphin-dev'
            $dolphin.Category | Should -Be 'Nintendo'
            $dolphin.Available | Should -Be $true
        }

        It 'Prefers preferred command variants' {
            Set-TestCommandAvailabilityState -CommandName 'dolphin-dev'
            Set-TestCommandAvailabilityState -CommandName 'dolphin-nightly'
            Set-TestCommandAvailabilityState -CommandName 'dolphin'
            Mark-TestCommandsUnavailable -CommandNames @('dolphin-nightly', 'dolphin')

            $result = Get-EmulatorList

            $dolphin = $result | Where-Object { $_.Name -eq 'Dolphin' }
            $dolphin | Should -Not -BeNullOrEmpty
            $dolphin.Command | Should -Be 'dolphin-dev'
        }

        It 'Groups emulators by category' {
            Set-TestCommandAvailabilityState -CommandName 'dolphin-dev'
            Set-TestCommandAvailabilityState -CommandName 'rpcs3'
            Set-TestCommandAvailabilityState -CommandName 'xemu'

            $result = Get-EmulatorList

            $nintendo = $result | Where-Object { $_.Category -eq 'Nintendo' }
            $sony = $result | Where-Object { $_.Category -eq 'Sony' }
            $microsoft = $result | Where-Object { $_.Category -eq 'Microsoft' }

            $nintendo | Should -Not -BeNullOrEmpty
            $sony | Should -Not -BeNullOrEmpty
            $microsoft | Should -Not -BeNullOrEmpty
        }
    }
}
