# game-emulators.ps1

Game console emulators fragment.

## Overview

This fragment provides wrapper functions for game console emulators, including Nintendo, Sony, Microsoft, Sega, and multi-system emulators. Functions support launching emulators, listing available emulators, and automatically selecting the appropriate emulator based on ROM file extensions.

## Functions

### Start-Dolphin

Launches the Dolphin emulator (GameCube/Wii).

**Syntax:**

```powershell
Start-Dolphin [-RomPath <string>] [-Fullscreen] [<CommonParameters>]
```

**Parameters:**

- `-RomPath` (Optional): Path to a ROM file to launch.
- `-Fullscreen` (Switch): Launch in fullscreen mode.

**Examples:**

```powershell
# Launch Dolphin emulator
Start-Dolphin

# Launch Dolphin with a ROM file
Start-Dolphin -RomPath "game.iso"

# Launch Dolphin in fullscreen mode
Start-Dolphin -RomPath "game.iso" -Fullscreen
```

**Supported Tools:**

- `dolphin-dev` - Dolphin development build (preferred)
- `dolphin-nightly` - Dolphin nightly build (fallback)
- `dolphin` - Dolphin stable build (fallback)

**Notes:**

- Prefers dolphin-dev over dolphin-nightly over dolphin when multiple are available
- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Start-Ryujinx

Launches the Ryujinx emulator (Nintendo Switch).

**Syntax:**

```powershell
Start-Ryujinx [-RomPath <string>] [-Fullscreen] [<CommonParameters>]
```

**Parameters:**

- `-RomPath` (Optional): Path to a ROM file to launch.
- `-Fullscreen` (Switch): Launch in fullscreen mode.

**Examples:**

```powershell
# Launch Ryujinx emulator
Start-Ryujinx

# Launch Ryujinx with a ROM file
Start-Ryujinx -RomPath "game.nsp"

# Launch Ryujinx in fullscreen mode
Start-Ryujinx -RomPath "game.nsp" -Fullscreen
```

**Supported Tools:**

- `ryujinx-canary` - Ryujinx canary build (preferred)
- `ryujinx` - Ryujinx stable build (fallback)

**Notes:**

- Prefers ryujinx-canary over ryujinx when both are available
- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Start-RetroArch

Launches RetroArch multi-system emulator frontend.

**Syntax:**

```powershell
Start-RetroArch [-RomPath <string>] [-Core <string>] [-Fullscreen] [<CommonParameters>]
```

**Parameters:**

- `-RomPath` (Optional): Path to a ROM file to launch.
- `-Core` (Optional): Core to use (e.g., 'snes9x', 'mupen64plus', 'mednafen_psx').
- `-Fullscreen` (Switch): Launch in fullscreen mode.

**Examples:**

```powershell
# Launch RetroArch
Start-RetroArch

# Launch RetroArch with a ROM file
Start-RetroArch -RomPath "game.sfc"

# Launch RetroArch with specific core
Start-RetroArch -RomPath "game.sfc" -Core "snes9x" -Fullscreen
```

**Supported Tools:**

- `retroarch-nightly` - RetroArch nightly build (preferred)
- `retroarch` - RetroArch stable build (fallback)

**Notes:**

- Prefers retroarch-nightly over retroarch when both are available
- Supports many console cores (SNES, N64, PS1, etc.)
- Creates process asynchronously (non-blocking)
- Returns nothing on success

---

### Get-EmulatorList

Lists available emulators on the system.

**Syntax:**

```powershell
Get-EmulatorList [<CommonParameters>]
```

**Examples:**

```powershell
# List all available emulators
Get-EmulatorList

# Filter by category
Get-EmulatorList | Where-Object { $_.Category -eq 'Nintendo' }
```

**Outputs:**

Returns an array of objects with the following properties:

- `Name` - Emulator name (e.g., "Dolphin", "Ryujinx")
- `Category` - Console category (e.g., "Nintendo", "Sony", "Microsoft", "Sega", "Multi-System", "Arcade")
- `Command` - Command name used to launch the emulator
- `Available` - Boolean indicating if the emulator is available

**Notes:**

- Checks for installed emulators using `Test-CachedCommand`
- Groups emulators by console/system category
- Prefers development/nightly builds over stable builds
- Returns empty array if no emulators are available

---

### Launch-Game

Launches a game ROM with the appropriate emulator based on file extension.

**Syntax:**

```powershell
Launch-Game -RomPath <string> [-Fullscreen] [<CommonParameters>]
```

**Parameters:**

- `-RomPath` (Required): Path to the ROM file to launch.
- `-Fullscreen` (Switch): Launch in fullscreen mode.

**Examples:**

```powershell
# Launch a GameCube ROM
Launch-Game -RomPath "game.iso"

# Launch a Switch ROM in fullscreen
Launch-Game -RomPath "game.nsp" -Fullscreen

# Launch a SNES ROM
Launch-Game -RomPath "game.sfc"
```

**Supported ROM Formats:**

- **GameCube/Wii**: `.gcm`, `.iso`, `.wbfs`, `.rvz`, `.wad`
- **Nintendo Switch**: `.nsp`, `.xci`
- **Nintendo 64**: `.n64`, `.z64`, `.v64`
- **Nintendo 3DS**: `.3ds`, `.cia`
- **Nintendo DS**: `.nds`
- **SNES**: `.snes`, `.sfc`, `.smc`
- **PlayStation**: `.ps3`, `.ps2`, `.psx`
- **PSP**: `.cso`
- **PS Vita**: `.vpk`
- **Xbox**: `.xex`, `.xbe`
- **Dreamcast**: `.gdi`, `.chd`
- **Arcade**: `.zip`, `.7z`

**Notes:**

- Automatically detects appropriate emulator based on file extension
- Falls back to RetroArch for unknown extensions
- Validates ROM file exists before launching
- Passes fullscreen flag to selected emulator

---

## Installation

Install emulators using Scoop:

```powershell
# Nintendo emulators
scoop install dolphin-dev
scoop install ryujinx-canary
scoop install cemu-dev
scoop install project64
scoop install lime3ds
scoop install melonds
scoop install bsnes
scoop install snes9x-dev

# Sony emulators
scoop install rpcs3
scoop install pcsx2-dev
scoop install duckstation-preview
scoop install ppsspp-dev
scoop install vita3k

# Microsoft emulators
scoop install xemu
scoop install xenia-canary

# Sega emulators
scoop install flycast
scoop install redream-dev

# Multi-system
scoop install retroarch-nightly
scoop install pegasus
scoop install steam-rom-manager

# Arcade
scoop install mame
```

## Error Handling

All functions gracefully degrade when tools are not installed:

- Functions return `$null` or empty when tools are unavailable
- Warning messages are displayed with installation hints
- No errors are thrown for missing tools (unless explicitly requested with `-ErrorAction Stop`)

## Testing

Comprehensive test coverage includes:

- Unit tests for each function
- Integration tests for module loading and function registration
- Performance tests for load time and execution speed
- Graceful degradation tests for missing tools

Run tests:

```powershell
# Unit tests
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/game-emulators.ps1

# Integration tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path tests/integration/tools/game-emulators.tests.ps1

# Performance tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Path tests/performance/game-emulators-performance.tests.ps1
```

## Notes

- All emulator launches are non-blocking (asynchronous)
- Functions prefer development/nightly builds over stable builds for better compatibility
- ROM file validation is performed before launching
- Unknown ROM formats fall back to RetroArch (supports many formats)
- Emulator detection uses cached command checks for performance
