# Get-ChocoPackageInfo

## Synopsis

Shows information about Chocolatey packages.

## Description

Displays detailed information about specified packages, including version, description, and dependencies.

## Signature

```powershell
Get-ChocoPackageInfo
```

## Parameters

### -Packages

Package names to get information for.

### -Source

Source to search in.


## Examples

### Example 1

`powershell
Get-ChocoPackageInfo git
        Shows detailed information about the git package.
``

### Example 2

`powershell
Get-ChocoPackageInfo git, vscode
        Shows information for multiple packages.
``

## Aliases

This function has the following aliases:

- `choinfo` - Shows information about Chocolatey packages.


## Source

Defined in: ..\profile.d\chocolatey.ps1
