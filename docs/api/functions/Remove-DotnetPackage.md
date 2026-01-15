# Remove-DotnetPackage

## Synopsis

Removes NuGet packages from .NET projects.

## Description

Removes packages from project files. Supports project specification.

## Signature

```powershell
Remove-DotnetPackage
```

## Parameters

### -Packages

Package names to remove.

### -Project

Project file path (--project).


## Examples

### Example 1

`powershell
Remove-DotnetPackage Newtonsoft.Json
        Removes Newtonsoft.Json from the current project.
``

## Aliases

This function has the following aliases:

- `dotnet-remove` - Removes NuGet packages from .NET projects.


## Source

Defined in: ..\profile.d\dotnet.ps1
