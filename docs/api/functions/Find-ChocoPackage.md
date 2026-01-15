# Find-ChocoPackage

## Synopsis

Searches for Chocolatey packages.

## Description

Searches for available packages in Chocolatey repositories.

## Signature

```powershell
Find-ChocoPackage
```

## Parameters

### -Query

Search query string.

### -Exact

Search for exact package name match.


## Examples

### Example 1

`powershell
Find-ChocoPackage git
        Searches for packages containing "git".
``

### Example 2

`powershell
Find-ChocoPackage git -Exact
        Searches for exact package name "git".
``

## Aliases

This function has the following aliases:

- `chofind` - Searches for Chocolatey packages.
- `chosearch` - Searches for Chocolatey packages.


## Source

Defined in: ..\profile.d\chocolatey.ps1
