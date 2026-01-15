# Flash-Android

## Synopsis

Flashes Android device firmware using PixelFlasher.

## Description

Launches PixelFlasher for flashing Android device firmware. PixelFlasher is a GUI tool for Android device flashing.

## Signature

```powershell
Flash-Android
```

## Parameters

### -FirmwarePath

Path to firmware file (optional - can be selected in GUI).


## Outputs

None.


## Examples

### Example 1

`powershell
Flash-Android
        
        Launches PixelFlasher.
``

### Example 2

`powershell
Flash-Android -FirmwarePath "firmware.zip"
        
        Launches PixelFlasher with firmware file path.
``

## Source

Defined in: ..\profile.d\mobile-dev.ps1
