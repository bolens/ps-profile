# ===============================================
# profile-game-emulators-launch.tests.ps1
# Unit tests for Launch-Game function
# ===============================================

function global:Install-TestEmulatorLaunchStub {
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName
    )

    Set-Item -Path "Function:\$FunctionName" -Value ([scriptblock]::Create(@"
        param([string]`$RomPath, [switch]`$Fullscreen)
        `$global:TestEmulatorLaunchCapture = @{
            Function   = '$FunctionName'
            RomPath    = `$RomPath
            Fullscreen = `$Fullscreen.IsPresent
        }
"@)) -Force
}

function global:Reset-TestEmulatorLaunchStubs {
    if ($script:OriginalStartDolphin) {
        Set-Item -Path Function:\Start-Dolphin -Value $script:OriginalStartDolphin -Force
    }
    if ($script:OriginalStartRyujinx) {
        Set-Item -Path Function:\Start-Ryujinx -Value $script:OriginalStartRyujinx -Force
    }
    if ($script:OriginalStartRetroArch) {
        Set-Item -Path Function:\Start-RetroArch -Value $script:OriginalStartRetroArch -Force
    }

    $global:TestEmulatorLaunchCapture = $null
}

function Install-TestEmulatorLaunchStub {
    global:Install-TestEmulatorLaunchStub @args
}

function Reset-TestEmulatorLaunchStubs {
    global:Reset-TestEmulatorLaunchStubs @args
}

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
    . (Join-Path $script:ProfileDir 'game-emulators.ps1')

    $script:OriginalStartDolphin = ${function:Start-Dolphin}
    $script:OriginalStartRyujinx = ${function:Start-Ryujinx}
    $script:OriginalStartRetroArch = ${function:Start-RetroArch}
    $script:TestRomDirectory = New-TestTempDirectory -Prefix 'LaunchGameRom'
}

Describe 'game-emulators.ps1 - Launch-Game' {
    BeforeEach {
        Reset-TestEmulatorLaunchStubs
    }

    AfterAll {
        Reset-TestEmulatorLaunchStubs
    }

    Context 'ROM file validation' {
        It 'Returns null when ROM file does not exist' {
            $missingRom = Join-Path (New-TestTempDirectory -Prefix 'LaunchGameMissing') 'nonexistent.iso'

            $result = Launch-Game -RomPath $missingRom -ErrorAction SilentlyContinue

            $result | Should -BeNullOrEmpty
            $global:TestEmulatorLaunchCapture | Should -BeNullOrEmpty
        }
    }

    Context 'Extension-based emulator selection' {
        It 'Launches GameCube ROM with Dolphin' {
            Install-TestEmulatorLaunchStub -FunctionName 'Start-Dolphin'
            $romPath = Join-Path $script:TestRomDirectory 'game.gcm'
            Set-Content -Path $romPath -Value 'fake rom'

            Launch-Game -RomPath $romPath -ErrorAction SilentlyContinue

            $global:TestEmulatorLaunchCapture.Function | Should -Be 'Start-Dolphin'
            $global:TestEmulatorLaunchCapture.RomPath | Should -Be $romPath
        }

        It 'Launches Switch ROM with Ryujinx' {
            Install-TestEmulatorLaunchStub -FunctionName 'Start-Ryujinx'
            $romPath = Join-Path $script:TestRomDirectory 'game.nsp'
            Set-Content -Path $romPath -Value 'fake rom'

            Launch-Game -RomPath $romPath -ErrorAction SilentlyContinue

            $global:TestEmulatorLaunchCapture.Function | Should -Be 'Start-Ryujinx'
            $global:TestEmulatorLaunchCapture.RomPath | Should -Be $romPath
        }

        It 'Launches SNES ROM with RetroArch' {
            Install-TestEmulatorLaunchStub -FunctionName 'Start-RetroArch'
            $romPath = Join-Path $script:TestRomDirectory 'game.sfc'
            Set-Content -Path $romPath -Value 'fake rom'

            Launch-Game -RomPath $romPath -ErrorAction SilentlyContinue

            $global:TestEmulatorLaunchCapture.Function | Should -Be 'Start-RetroArch'
            $global:TestEmulatorLaunchCapture.RomPath | Should -Be $romPath
        }

        It 'Passes fullscreen flag to emulator' {
            Install-TestEmulatorLaunchStub -FunctionName 'Start-Dolphin'
            $romPath = Join-Path $script:TestRomDirectory 'game.iso'
            Set-Content -Path $romPath -Value 'fake rom'

            Launch-Game -RomPath $romPath -Fullscreen -ErrorAction SilentlyContinue

            $global:TestEmulatorLaunchCapture.Fullscreen | Should -Be $true
        }

        It 'Falls back to RetroArch for unknown extensions' {
            Install-TestEmulatorLaunchStub -FunctionName 'Start-RetroArch'
            $romPath = Join-Path $script:TestRomDirectory 'game.unknown'
            Set-Content -Path $romPath -Value 'fake rom'

            Launch-Game -RomPath $romPath -ErrorAction SilentlyContinue

            $global:TestEmulatorLaunchCapture.Function | Should -Be 'Start-RetroArch'
            $global:TestEmulatorLaunchCapture.RomPath | Should -Be $romPath
        }
    }
}
