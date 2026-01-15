# Start-Ryujinx

## Synopsis

Launches the Ryujinx emulator (Nintendo Switch).

## Description

Launches Ryujinx emulator. Prefers ryujinx-canary, falls back to ryujinx. Optionally opens a ROM file.

## Signature

```powershell
Start-Ryujinx
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
Start-Ryujinx
        
        Launches Ryujinx emulator.
``

### Example 2

`powershell
Start-Ryujinx -RomPath "game.nsp" -Fullscreen
        
        Launches Ryujinx with a ROM in fullscreen mode.
``

## Source

Defined in: ..\profile.d\game-emulators.ps1
