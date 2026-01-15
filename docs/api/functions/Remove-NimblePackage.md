# Remove-NimblePackage

## Synopsis

Removes Nim packages.

## Description

Removes packages. Supports --global flag.

## Signature

```powershell
Remove-NimblePackage
```

## Parameters

### -Packages

Package names to remove.

### -Global

Remove from global packages (--global).


## Examples

### Example 1

`powershell
Remove-NimblePackage jester
        Removes jester from local installation.
``

### Example 2

`powershell
Remove-NimblePackage jester -Global
        Removes jester from global installation.
``

## Aliases

This function has the following aliases:

- `nimble-remove` - Removes Nim packages.
- `nimble-uninstall` - Removes Nim packages.


## Source

Defined in: ..\profile.d\nimble.ps1
