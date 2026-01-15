# ===============================================
# game-emulators.ps1
# Game console emulators
# ===============================================
# Tier: optional
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Game console emulators fragment.

.DESCRIPTION
    Provides wrapper functions for game console emulators:
    - Nintendo: Dolphin (GameCube/Wii), Ryujinx/Yuzu (Switch), Cemu (Wii U), Project64 (N64), Lime3DS (3DS), MelonDS (DS), bsnes/snes9x (SNES)
    - Sony: RPCS3 (PS3), PCSX2 (PS2), DuckStation (PS1), PPSSPP (PSP), Vita3K (PS Vita)
    - Microsoft: Xemu (Xbox), Xenia (Xbox 360)
    - Sega: Flycast/Redream (Dreamcast)
    - Multi-system: RetroArch, Pegasus, Steam ROM Manager

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module provides game emulation capabilities.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'game-emulators') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
        }
        else {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # Start-Dolphin - Launch Dolphin emulator
    # ===============================================

    <#
    .SYNOPSIS
        Launches the Dolphin emulator (GameCube/Wii).
    
    .DESCRIPTION
        Launches Dolphin emulator. Prefers dolphin-dev, falls back to dolphin-nightly or dolphin.
        Optionally opens a ROM file.
    
    .PARAMETER RomPath
        Optional path to a ROM file to launch.
    
    .PARAMETER Fullscreen
        Launch in fullscreen mode.
    
    .EXAMPLE
        Start-Dolphin
        
        Launches Dolphin emulator.
    
    .EXAMPLE
        Start-Dolphin -RomPath "game.iso" -Fullscreen
        
        Launches Dolphin with a ROM in fullscreen mode.
    
    .OUTPUTS
        None.
    #>
    function Start-Dolphin {
        [CmdletBinding()]
        param(
            [string]$RomPath,
            
            [switch]$Fullscreen
        )

        # Prefer dolphin-dev, fallback to dolphin-nightly or dolphin
        $tool = $null
        if (Test-CachedCommand 'dolphin-dev') {
            $tool = 'dolphin-dev'
        }
        elseif (Test-CachedCommand 'dolphin-nightly') {
            $tool = 'dolphin-nightly'
        }
        elseif (Test-CachedCommand 'dolphin') {
            $tool = 'dolphin'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'dolphin-dev' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'dolphin-dev' -InstallHint $installHint
            }
            else {
                Write-Warning "dolphin-dev, dolphin-nightly, or dolphin is not installed. Install it with: scoop install dolphin-dev"
            }
            return
        }

        $arguments = @()
        
        if ($RomPath) {
            if (-not (Test-Path -LiteralPath $RomPath)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("ROM file not found: $RomPath"),
                            'RomFileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $RomPath
                        )) -OperationName 'emulator.dolphin.launch' -Context @{ rom_path = $RomPath }
                }
                else {
                    Write-Error "ROM file not found: $RomPath"
                }
                return
            }
            $arguments += $RomPath
        }
        
        if ($Fullscreen) {
            $arguments += '--fullscreen'
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'emulator.dolphin.launch' -Context @{
                rom_path   = $RomPath
                fullscreen = $Fullscreen.IsPresent
            } -ScriptBlock {
                Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch Dolphin: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Start-Ryujinx - Launch Ryujinx emulator
    # ===============================================

    <#
    .SYNOPSIS
        Launches the Ryujinx emulator (Nintendo Switch).
    
    .DESCRIPTION
        Launches Ryujinx emulator. Prefers ryujinx-canary, falls back to ryujinx.
        Optionally opens a ROM file.
    
    .PARAMETER RomPath
        Optional path to a ROM file to launch.
    
    .PARAMETER Fullscreen
        Launch in fullscreen mode.
    
    .EXAMPLE
        Start-Ryujinx
        
        Launches Ryujinx emulator.
    
    .EXAMPLE
        Start-Ryujinx -RomPath "game.nsp" -Fullscreen
        
        Launches Ryujinx with a ROM in fullscreen mode.
    
    .OUTPUTS
        None.
    #>
    function Start-Ryujinx {
        [CmdletBinding()]
        param(
            [string]$RomPath,
            
            [switch]$Fullscreen
        )

        # Prefer ryujinx-canary, fallback to ryujinx
        $tool = $null
        if (Test-CachedCommand 'ryujinx-canary') {
            $tool = 'ryujinx-canary'
        }
        elseif (Test-CachedCommand 'ryujinx') {
            $tool = 'ryujinx'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'ryujinx-canary' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'ryujinx-canary' -InstallHint $installHint
            }
            else {
                Write-Warning "ryujinx-canary or ryujinx is not installed. Install it with: scoop install ryujinx-canary"
            }
            return
        }

        $arguments = @()
        
        if ($RomPath) {
            if (-not (Test-Path -LiteralPath $RomPath)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("ROM file not found: $RomPath"),
                            'RomFileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $RomPath
                        )) -OperationName 'emulator.ryujinx.launch' -Context @{ rom_path = $RomPath }
                }
                else {
                    Write-Error "ROM file not found: $RomPath"
                }
                return
            }
            $arguments += $RomPath
        }
        
        if ($Fullscreen) {
            $arguments += '--fullscreen'
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'emulator.ryujinx.launch' -Context @{
                rom_path   = $RomPath
                fullscreen = $Fullscreen.IsPresent
            } -ScriptBlock {
                Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch Ryujinx: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Start-RetroArch - Launch RetroArch
    # ===============================================

    <#
    .SYNOPSIS
        Launches RetroArch multi-system emulator frontend.
    
    .DESCRIPTION
        Launches RetroArch, a multi-system emulator frontend supporting many consoles.
        Optionally opens a ROM file.
    
    .PARAMETER RomPath
        Optional path to a ROM file to launch.
    
    .PARAMETER Core
        Core to use (e.g., 'snes9x', 'mupen64plus', 'mednafen_psx').
    
    .PARAMETER Fullscreen
        Launch in fullscreen mode.
    
    .EXAMPLE
        Start-RetroArch
        
        Launches RetroArch.
    
    .EXAMPLE
        Start-RetroArch -RomPath "game.sfc" -Core "snes9x" -Fullscreen
        
        Launches RetroArch with a ROM using the SNES9x core in fullscreen.
    
    .OUTPUTS
        None.
    #>
    function Start-RetroArch {
        [CmdletBinding()]
        param(
            [string]$RomPath,
            
            [string]$Core,
            
            [switch]$Fullscreen
        )

        # Prefer retroarch-nightly, fallback to retroarch
        $tool = $null
        if (Test-CachedCommand 'retroarch-nightly') {
            $tool = 'retroarch-nightly'
        }
        elseif (Test-CachedCommand 'retroarch') {
            $tool = 'retroarch'
        }

        if (-not $tool) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'retroarch-nightly' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'retroarch-nightly' -InstallHint $installHint
            }
            else {
                Write-Warning "retroarch-nightly or retroarch is not installed. Install it with: scoop install retroarch-nightly"
            }
            return
        }

        $arguments = @()
        
        if ($Core) {
            $arguments += '-L', $Core
        }
        
        if ($RomPath) {
            if (-not (Test-Path -LiteralPath $RomPath)) {
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                            [System.IO.FileNotFoundException]::new("ROM file not found: $RomPath"),
                            'RomFileNotFound',
                            [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                            $RomPath
                        )) -OperationName 'emulator.retroarch.launch' -Context @{ rom_path = $RomPath }
                }
                else {
                    Write-Error "ROM file not found: $RomPath"
                }
                return
            }
            $arguments += $RomPath
        }
        
        if ($Fullscreen) {
            $arguments += '--fullscreen'
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            Invoke-WithWideEvent -OperationName 'emulator.retroarch.launch' -Context @{
                rom_path   = $RomPath
                core       = $Core
                fullscreen = $Fullscreen.IsPresent
            } -ScriptBlock {
                Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
            } | Out-Null
        }
        else {
            try {
                Start-Process -FilePath $tool -ArgumentList $arguments -ErrorAction Stop
            }
            catch {
                Write-Error "Failed to launch RetroArch: $($_.Exception.Message)"
            }
        }
    }

    # ===============================================
    # Get-EmulatorList - List available emulators
    # ===============================================

    <#
    .SYNOPSIS
        Lists available emulators on the system.
    
    .DESCRIPTION
        Checks for installed emulators and returns a list of available ones.
        Groups by console/system.
    
    .EXAMPLE
        Get-EmulatorList
        
        Lists all available emulators.
    
    .OUTPUTS
        System.Object[]. Array of emulator information objects.
    #>
    function Get-EmulatorList {
        [CmdletBinding()]
        [OutputType([object[]])]
        param()

        $emulators = @()
        
        # Nintendo
        $nintendoEmulators = @{
            'Dolphin'     = @('dolphin-dev', 'dolphin-nightly', 'dolphin')
            'Ryujinx'     = @('ryujinx-canary', 'ryujinx')
            'Yuzu'        = @('yuzu')
            'Cemu'        = @('cemu-dev', 'cemu')
            'Project64'   = @('project64')
            'Mupen64Plus' = @('mupen64plus')
            'Lime3DS'     = @('lime3ds')
            'MelonDS'     = @('melonds')
            'bsnes'       = @('bsnes', 'bsnes-hd-beta', 'bsnes-mt')
            'SNES9x'      = @('snes9x-dev', 'snes9x')
        }
        
        # Sony
        $sonyEmulators = @{
            'RPCS3'       = @('rpcs3')
            'PCSX2'       = @('pcsx2-dev', 'pcsx2')
            'DuckStation' = @('duckstation-preview', 'duckstation')
            'PPSSPP'      = @('ppsspp-dev', 'ppsspp')
            'Vita3K'      = @('vita3k')
        }
        
        # Microsoft
        $microsoftEmulators = @{
            'Xemu'  = @('xemu')
            'Xenia' = @('xenia-canary', 'xenia')
        }
        
        # Sega
        $segaEmulators = @{
            'Flycast' = @('flycast')
            'Redream' = @('redream-dev', 'redream')
        }
        
        # Multi-system
        $multiSystemEmulators = @{
            'RetroArch'         = @('retroarch-nightly', 'retroarch')
            'Pegasus'           = @('pegasus')
            'Steam ROM Manager' = @('steam-rom-manager')
        }
        
        # MAME
        $arcadeEmulators = @{
            'MAME' = @('mame')
        }
        
        $allEmulators = @{
            'Nintendo'     = $nintendoEmulators
            'Sony'         = $sonyEmulators
            'Microsoft'    = $microsoftEmulators
            'Sega'         = $segaEmulators
            'Multi-System' = $multiSystemEmulators
            'Arcade'       = $arcadeEmulators
        }
        
        foreach ($category in $allEmulators.Keys) {
            foreach ($emulatorName in $allEmulators[$category].Keys) {
                $commands = $allEmulators[$category][$emulatorName]
                $foundCommand = $null
                
                foreach ($cmd in $commands) {
                    if (Test-CachedCommand $cmd) {
                        $foundCommand = $cmd
                        break
                    }
                }
                
                if ($foundCommand) {
                    $emulators += [PSCustomObject]@{
                        Name      = $emulatorName
                        Category  = $category
                        Command   = $foundCommand
                        Available = $true
                    }
                }
            }
        }
        
        return $emulators
    }

    # ===============================================
    # Launch-Game - Launch game with appropriate emulator
    # ===============================================

    <#
    .SYNOPSIS
        Launches a game ROM with the appropriate emulator based on file extension.
    
    .DESCRIPTION
        Detects the appropriate emulator based on ROM file extension and launches it.
        Supports common ROM formats (.iso, .nsp, .xci, .gcm, .wbfs, .rvz, .wad, .n64, .z64, .v64, .3ds, .cia, .nds, .snes, .sfc, .smc, .ps3, .ps2, .psx, .iso, .cso, .vpk, .xex, .xbe, .gdi, .chd, .zip, .7z).
    
    .PARAMETER RomPath
        Path to the ROM file to launch.
    
    .PARAMETER Fullscreen
        Launch in fullscreen mode.
    
    .EXAMPLE
        Launch-Game -RomPath "game.iso"
        
        Launches a game ROM with the appropriate emulator.
    
    .OUTPUTS
        None.
    #>
    function Launch-Game {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory = $true)]
            [string]$RomPath,
            
            [switch]$Fullscreen
        )

        if (-not (Test-Path -LiteralPath $RomPath)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.FileNotFoundException]::new("ROM file not found: $RomPath"),
                        'RomFileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $RomPath
                    )) -OperationName 'emulator.game.launch' -Context @{ rom_path = $RomPath }
            }
            else {
                Write-Error "ROM file not found: $RomPath"
            }
            return
        }

        $extension = [System.IO.Path]::GetExtension($RomPath).ToLower()
        
        # Map extensions to emulators
        $emulatorMap = @{
            # GameCube/Wii
            '.gcm'  = 'Start-Dolphin'
            '.iso'  = 'Start-Dolphin'  # Could be multiple systems, try Dolphin first
            '.wbfs' = 'Start-Dolphin'
            '.rvz'  = 'Start-Dolphin'
            '.wad'  = 'Start-Dolphin'
            
            # Nintendo Switch
            '.nsp'  = 'Start-Ryujinx'
            '.xci'  = 'Start-Ryujinx'
            
            # N64
            '.n64'  = 'Start-RetroArch'
            '.z64'  = 'Start-RetroArch'
            '.v64'  = 'Start-RetroArch'
            
            # 3DS
            '.3ds'  = 'Start-RetroArch'
            '.cia'  = 'Start-RetroArch'
            
            # DS
            '.nds'  = 'Start-RetroArch'
            
            # SNES
            '.snes' = 'Start-RetroArch'
            '.sfc'  = 'Start-RetroArch'
            '.smc'  = 'Start-RetroArch'
            
            # PS3
            '.ps3'  = 'Start-RetroArch'
            
            # PS2
            '.ps2'  = 'Start-RetroArch'
            
            # PS1
            '.psx'  = 'Start-RetroArch'
            
            # PSP
            '.cso'  = 'Start-RetroArch'
            
            # PS Vita
            '.vpk'  = 'Start-RetroArch'
            
            # Xbox
            '.xex'  = 'Start-RetroArch'
            '.xbe'  = 'Start-RetroArch'
            
            # Dreamcast
            '.gdi'  = 'Start-RetroArch'
            '.chd'  = 'Start-RetroArch'
            
            # Arcade/MAME
            '.zip'  = 'Start-RetroArch'
            '.7z'   = 'Start-RetroArch'
        }
        
        if (-not $emulatorMap.ContainsKey($extension)) {
            Write-Warning "Unknown ROM format: $extension. Attempting to launch with RetroArch..."
            Start-RetroArch -RomPath $RomPath -Fullscreen:$Fullscreen
            return
        }
        
        $emulatorFunction = $emulatorMap[$extension]
        
        if ($Fullscreen) {
            & $emulatorFunction -RomPath $RomPath -Fullscreen
        }
        else {
            & $emulatorFunction -RomPath $RomPath
        }
    }

    # Register functions
    if (Get-Command -Name 'Set-AgentModeFunction' -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Start-Dolphin' -Body ${function:Start-Dolphin}
        Set-AgentModeFunction -Name 'Start-Ryujinx' -Body ${function:Start-Ryujinx}
        Set-AgentModeFunction -Name 'Start-RetroArch' -Body ${function:Start-RetroArch}
        Set-AgentModeFunction -Name 'Get-EmulatorList' -Body ${function:Get-EmulatorList}
        Set-AgentModeFunction -Name 'Launch-Game' -Body ${function:Launch-Game}
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'game-emulators'
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: game-emulators" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load game-emulators fragment: $($_.Exception.Message)"
        }
    }
}

