# Add-Path

## Synopsis

Adds a directory to the PATH environment variable.

## Description

Adds the specified directory to the PATH environment variable if it doesn't already exist.

## Signature

```powershell
Add-Path
```

## Parameters

### -Path

The directory path to add to PATH.

### -Global

If specified, modifies the system-wide PATH; otherwise, modifies user PATH.


## Examples

### Example 1

```powershell
Add-Path -Path ./path
```

## Source

Defined in: ../profile.d/utilities-modules/system/utilities-env.ps1
