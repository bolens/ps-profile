# Start-AndroidStudio

## Synopsis

Launches Android Studio IDE.

## Description

Launches Android Studio for Android app development. Prefers android-studio-canary, falls back to android-studio.

## Signature

```powershell
Start-AndroidStudio
```

## Parameters

### -ProjectPath

Optional path to project to open.


## Outputs

None.


## Examples

### Example 1

`powershell
Start-AndroidStudio
        
        Launches Android Studio.
``

### Example 2

`powershell
Start-AndroidStudio -ProjectPath "C:\Projects\MyApp"
        
        Launches Android Studio and opens a project.
``

## Source

Defined in: ..\profile.d\mobile-dev.ps1
