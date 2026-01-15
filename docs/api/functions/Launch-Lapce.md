# Launch-Lapce

## Synopsis

Launches Lapce editor.

## Description

Launches Lapce, a fast code editor. Prefers lapce-nightly, falls back to lapce. Optionally opens files or directories.

## Signature

```powershell
Launch-Lapce
```

## Parameters

### -Path

File or directory path to open. Defaults to current directory.


## Outputs

None.


## Examples

### Example 1

`powershell
Launch-Lapce
        
        Launches Lapce.
``

### Example 2

`powershell
Launch-Lapce -Path "C:\Projects\MyApp"
        
        Opens a directory in Lapce.
``

## Source

Defined in: ..\profile.d\editors.ps1
