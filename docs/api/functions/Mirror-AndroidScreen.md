# Mirror-AndroidScreen

## Synopsis

Mirrors Android device screen using scrcpy.

## Description

Launches scrcpy to mirror and control Android device screen. Supports various display options and quality settings.

## Signature

```powershell
Mirror-AndroidScreen
```

## Parameters

### -DeviceId

Device ID to mirror. If not provided, uses first connected device.

### -Fullscreen

Start in fullscreen mode.

### -StayAwake

Keep device awake while mirroring.

### -MaxSize

Maximum resolution (e.g., "1920" for 1920px width).

### -Bitrate

Video bitrate in Mbps. Defaults to 8.


## Outputs

None.


## Examples

### Example 1

`powershell
Mirror-AndroidScreen
        
        Mirrors Android device screen.
``

### Example 2

`powershell
Mirror-AndroidScreen -Fullscreen -StayAwake
        
        Mirrors Android device screen in fullscreen with stay-awake enabled.
``

## Source

Defined in: ..\profile.d\mobile-dev.ps1
