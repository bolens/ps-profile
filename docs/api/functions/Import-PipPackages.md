# Import-PipPackages

## Synopsis

Restores pip packages from a requirements.txt file.

## Description

Installs all packages listed in a requirements.txt file. This is useful for restoring packages after a system reinstall or on a new machine.

## Signature

```powershell
Import-PipPackages
```

## Parameters

### -Path

Path to the requirements.txt file to import. Defaults to "requirements.txt" in current directory.

### -User

Install to user site-packages (--user flag).


## Examples

### Example 1

`powershell
Import-PipPackages
        Restores packages from requirements.txt in current directory.
``

### Example 2

`powershell
Import-PipPackages -Path "C:\backup\pip-requirements.txt"
        Restores packages from a specific file.
``

### Example 3

`powershell
Import-PipPackages -User
        Restores packages to user directory.
``

## Aliases

This function has the following aliases:

- `pipimport` - Restores pip packages from a requirements.txt file.
- `piprestore` - Restores pip packages from a requirements.txt file.


## Source

Defined in: ..\profile.d\pip.ps1
