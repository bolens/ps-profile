# Get-WingetPackageInfo

## Synopsis

Shows information about winget packages.

## Description

Displays detailed information about specified packages, including version, description, publisher, and available versions.

## Signature

```powershell
Get-WingetPackageInfo
```

## Parameters

### -Packages

Package IDs or names to get information for.

### -Version

Show information for a specific version.

### -Source

Source to search in.


## Examples

### Example 1

`powershell
Get-WingetPackageInfo Git.Git
        Shows detailed information about the Git.Git package.
``

### Example 2

`powershell
Get-WingetPackageInfo Microsoft.VisualStudioCode
        Shows information for Visual Studio Code.
``

## Aliases

This function has the following aliases:

- `winget-info` - Shows information about winget packages.
- `winget-show` - Shows information about winget packages.


## Source

Defined in: ..\profile.d\winget.ps1
