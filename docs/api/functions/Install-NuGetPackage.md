# Install-NuGetPackage

## Synopsis

Installs packages using NuGet.

## Description

Installs packages using NuGet. Supports -Version, -Source, and -OutputDirectory flags.

## Signature

```powershell
Install-NuGetPackage
```

## Parameters

### -Packages

Package names to install.

### -Version

Specific version to install.

### -Source

Package source URL.

### -OutputDirectory

Directory to install packages to.


## Examples

### Example 1

`powershell
Install-NuGetPackage Newtonsoft.Json
        Installs Newtonsoft.Json.
``

### Example 2

`powershell
Install-NuGetPackage Newtonsoft.Json -Version 13.0.1
        Installs specific version.
``

## Aliases

This function has the following aliases:

- `nugetadd` - Installs packages using NuGet.
- `nugetinstall` - Installs packages using NuGet.


## Source

Defined in: ..\profile.d\nuget.ps1
