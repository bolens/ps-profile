# Start-RetroArch

## Synopsis

Launches RetroArch multi-system emulator frontend.

## Description

Launches RetroArch, a multi-system emulator frontend supporting many consoles. Optionally opens a ROM file.

## Signature

```powershell
Start-RetroArch
```

## Parameters

### -RomPath

Optional path to a ROM file to launch.

### -Core

Core to use (e.g., 'snes9x', 'mupen64plus', 'mednafen_psx').

### -Fullscreen

Launch in fullscreen mode.


## Outputs

None.


## Examples

### Example 1

`powershell
Start-RetroArch
        
        Launches RetroArch.
``

### Example 2

`powershell
Start-RetroArch -RomPath "game.sfc" -Core "snes9x" -Fullscreen
        
        Launches RetroArch with a ROM using the SNES9x core in fullscreen.
``

## Source

Defined in: ..\profile.d\game-emulators.ps1
