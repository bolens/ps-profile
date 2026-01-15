# Install-PythonPackage

## Synopsis

Installs Python packages using the best available tool.

## Description

Installs Python packages using the best available tool in order of preference: - uv (if available) - fastest option - pip (if available) - standard option Falls back gracefully if neither is available.

## Signature

```powershell
Install-PythonPackage
```

## Parameters

### -Packages

Package names to install. Can be used multiple times or as an array.

### -Arguments

Additional arguments to pass to the installer. Can be used multiple times or as an array.


## Outputs

System.String. Output from package installation.


## Examples

### Example 1

`powershell
Install-PythonPackage requests
        Installs requests using the best available tool.
``

### Example 2

`powershell
Install-PythonPackage pytest --dev
        Installs pytest as a dev dependency (uv only).
``

## Aliases

This function has the following aliases:

- `pyinstall` - Installs Python packages using the best available tool.


## Source

Defined in: ..\profile.d\lang-python.ps1
