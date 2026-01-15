# Connect-AndroidDevice

## Synopsis

Connects to an Android device via ADB.

## Description

Connects to an Android device using ADB (Android Debug Bridge). Can connect via USB or network (TCP/IP).

## Signature

```powershell
Connect-AndroidDevice
```

## Parameters

### -DeviceIp

IP address for network connection. If not provided, connects via USB.

### -Port

Port for network connection. Defaults to 5555.

### -ListDevices

List all connected devices.


## Outputs

System.String[]. List of connected devices or connection status.


## Examples

### Example 1

`powershell
Connect-AndroidDevice
        
        Connects to Android device via USB.
``

### Example 2

`powershell
Connect-AndroidDevice -DeviceIp "192.168.1.100"
        
        Connects to Android device via network.
``

### Example 3

`powershell
Connect-AndroidDevice -ListDevices
        
        Lists all connected Android devices.
``

## Source

Defined in: ..\profile.d\mobile-dev.ps1
