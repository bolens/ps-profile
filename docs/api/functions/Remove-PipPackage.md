# Remove-PipPackage

## Synopsis

Removes Python packages using pip.

## Description

Removes packages. Supports --user flag for user-installed packages.

## Signature

```powershell
Remove-PipPackage
```

## Parameters

### -Packages

Package names to remove.

### -User

Remove from user site-packages (--user).


## Examples

### Example 1

`powershell
Remove-PipPackage requests
        Removes requests from global installation.
``

### Example 2

`powershell
Remove-PipPackage requests -User
        Removes requests from user directory.
``

## Aliases

This function has the following aliases:

- `pipremove` - Removes Python packages using pip.
- `pipuninstall` - Removes Python packages using pip.


## Source

Defined in: ..\profile.d\pip.ps1
