# Add-DotnetPackage

## Synopsis

Adds NuGet packages to .NET projects.

## Description

Adds packages to project files. Supports --version and project specification.

## Signature

```powershell
Add-DotnetPackage
```

## Parameters

### -Packages

Package names to add.

### -Version

Package version to install (--version).

### -Project

Project file path (--project).


## Examples

### Example 1

`powershell
Add-DotnetPackage Newtonsoft.Json
        Adds Newtonsoft.Json to the current project.
``

### Example 2

`powershell
Add-DotnetPackage Newtonsoft.Json -Version 13.0.1
        Adds a specific version of Newtonsoft.Json.
``

## Aliases

This function has the following aliases:

- `dotnet-add` - Adds NuGet packages to .NET projects.


## Source

Defined in: ..\profile.d\dotnet.ps1
