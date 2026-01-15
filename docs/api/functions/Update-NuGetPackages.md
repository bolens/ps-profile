# Update-NuGetPackages

## Synopsis

Updates packages in packages.config.

## Description

Updates packages to their latest versions.

## Signature

```powershell
Update-NuGetPackages
```

## Parameters

### -Path

Path to packages.config file.

### -Id

Specific package ID to update.


## Examples

### Example 1

`powershell
Update-NuGetPackages
        Updates all packages in current directory.
``

### Example 2

`powershell
Update-NuGetPackages -Id Newtonsoft.Json
        Updates specific package.
``

## Aliases

This function has the following aliases:

- `nugetupdate` - Updates packages in packages.config.


## Source

Defined in: ..\profile.d\nuget.ps1
