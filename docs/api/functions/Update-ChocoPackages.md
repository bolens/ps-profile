# Update-ChocoPackages

## Synopsis

Updates Chocolatey packages.

## Description

Updates specified packages or all packages if no arguments provided.

## Signature

```powershell
Update-ChocoPackages
```

## Parameters

### -Packages

Package names to update (optional, updates all if omitted).

### -Yes

Auto-confirm all prompts.


## Examples

### Example 1

`powershell
Update-ChocoPackages
        Updates all packages.
``

### Example 2

`powershell
Update-ChocoPackages git
        Updates git package.
``

## Aliases

This function has the following aliases:

- `choupdate` - Updates Chocolatey packages.
- `choupgrade` - Updates Chocolatey packages.


## Source

Defined in: ..\profile.d\chocolatey.ps1
