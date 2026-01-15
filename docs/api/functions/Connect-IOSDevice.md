# Connect-IOSDevice

## Synopsis

Connects to an iOS device using libimobiledevice.

## Description

Connects to an iOS device and lists connected devices. Uses libimobiledevice tools for iOS device management.

## Signature

```powershell
Connect-IOSDevice
```

## Parameters

### -ListDevices

List all connected iOS devices.

### -DeviceId

Device UDID to connect to. If not provided, uses first connected device.


## Outputs

System.String[]. List of connected devices or device information.


## Examples

### Example 1

`powershell
Connect-IOSDevice
        
        Connects to iOS device.
``

### Example 2

`powershell
Connect-IOSDevice -ListDevices
        
        Lists all connected iOS devices.
``

## Source

Defined in: ..\profile.d\mobile-dev.ps1
