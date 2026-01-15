# Start-Dolphin

## Synopsis

Launches the Dolphin emulator (GameCube/Wii).

## Description

Launches Dolphin emulator. Prefers dolphin-dev, falls back to dolphin-nightly or dolphin. Optionally opens a ROM file.

## Signature

```powershell
Start-Dolphin
```

## Parameters

### -RomPath

Optional path to a ROM file to launch.

### -Fullscreen

Launch in fullscreen mode.


## Outputs

None.


## Examples

### Example 1

`powershell
Start-Dolphin
        
        Launches Dolphin emulator.
``

### Example 2

`powershell
Start-Dolphin -RomPath "game.iso" -Fullscreen
        
        Launches Dolphin with a ROM in fullscreen mode.
``

## Source

Defined in: ..\profile.d\game-emulators.ps1
