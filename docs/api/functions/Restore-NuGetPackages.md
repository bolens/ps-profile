# Restore-NuGetPackages

## Synopsis

Restores packages from packages.config or project.json.

## Description

Restores packages for a solution or project.

## Signature

```powershell
Restore-NuGetPackages
```

## Parameters

### -Path

Path to solution or project file.

### -Source

Package source URL.


## Examples

### Example 1

`powershell
Restore-NuGetPackages
        Restores packages in current directory.
``

### Example 2

`powershell
Restore-NuGetPackages -Path MyProject.sln
        Restores packages for solution.
``

## Aliases

This function has the following aliases:

- `nugetrestore` - Restores packages from packages.config or project.json.


## Source

Defined in: ..\profile.d\nuget.ps1
