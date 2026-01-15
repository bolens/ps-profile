# Launch-Game

## Synopsis

Launches a game ROM with the appropriate emulator based on file extension.

## Description

Detects the appropriate emulator based on ROM file extension and launches it. Supports common ROM formats (.iso, .nsp, .xci, .gcm, .wbfs, .rvz, .wad, .n64, .z64, .v64, .3ds, .cia, .nds, .snes, .sfc, .smc, .ps3, .ps2, .psx, .iso, .cso, .vpk, .xex, .xbe, .gdi, .chd, .zip, .7z).

## Signature

```powershell
Launch-Game
```

## Parameters

### -RomPath

Path to the ROM file to launch.

### -Fullscreen

Launch in fullscreen mode.


## Outputs

None.


## Examples

### Example 1

`powershell
Launch-Game -RomPath "game.iso"
        
        Launches a game ROM with the appropriate emulator.
``

## Source

Defined in: ..\profile.d\game-emulators.ps1
