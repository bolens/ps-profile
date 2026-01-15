# Remove-WingetPackage

## Synopsis

Removes packages using winget.

## Description

Uninstalls packages installed via winget.

## Signature

```powershell
Remove-WingetPackage
```

## Parameters

### -Packages

Package IDs or names to uninstall.


## Examples

### Example 1

`powershell
Remove-WingetPackage Microsoft.VisualStudioCode
        Uninstalls Visual Studio Code.
``

## Aliases

This function has the following aliases:

- `winget-remove` - Removes packages using winget.
- `winget-uninstall` - Removes packages using winget.


## Source

Defined in: ..\profile.d\winget.ps1
