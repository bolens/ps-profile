# Install-Apk

## Synopsis

Installs an APK file on Android device.

## Description

Installs an APK file on connected Android device using ADB. Supports installation options like replacing existing app or granting permissions.

## Signature

```powershell
Install-Apk
```

## Parameters

### -ApkPath

Path to the APK file to install.

### -DeviceId

Device ID to install on. If not provided, uses first connected device.

### -ReplaceExisting

Replace existing application if already installed.

### -GrantPermissions

Grant all runtime permissions automatically.


## Outputs

System.Boolean. True if installation succeeded, false otherwise.


## Examples

### Example 1

`powershell
Install-Apk -ApkPath "app.apk"
        
        Installs an APK file on Android device.
``

### Example 2

`powershell
Install-Apk -ApkPath "app.apk" -ReplaceExisting -GrantPermissions
        
        Installs APK, replacing existing app and granting all permissions.
``

## Source

Defined in: ..\profile.d\mobile-dev.ps1
