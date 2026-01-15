# Launch-Zed

## Synopsis

Launches Zed editor.

## Description

Launches Zed, a high-performance code editor. Prefers zed-nightly, falls back to zed. Optionally opens files or directories.

## Signature

```powershell
Launch-Zed
```

## Parameters

### -Path

File or directory path to open. Defaults to current directory.


## Outputs

None.


## Examples

### Example 1

`powershell
Launch-Zed
        
        Launches Zed.
``

### Example 2

`powershell
Launch-Zed -Path "C:\Projects\MyApp"
        
        Opens a directory in Zed.
``

## Source

Defined in: ..\profile.d\editors.ps1
