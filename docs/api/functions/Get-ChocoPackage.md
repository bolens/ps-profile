# Get-ChocoPackage

## Synopsis

Lists installed Chocolatey packages.

## Description

Shows all packages currently installed via Chocolatey.

## Signature

```powershell
Get-ChocoPackage
```

## Parameters

### -LocalOnly

Show only locally installed packages (default).

### -IncludePrograms

Include programs installed outside of Chocolatey.


## Examples

### Example 1

`powershell
Get-ChocoPackage
        Lists all installed Chocolatey packages.
``

## Aliases

This function has the following aliases:

- `cholist` - Lists installed Chocolatey packages.


## Source

Defined in: ..\profile.d\chocolatey.ps1
