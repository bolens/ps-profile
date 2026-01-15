# Install-AsdfTool

## Synopsis

Installs tools using asdf.

## Description

Installs tool versions. Supports version specification.

## Signature

```powershell
Install-AsdfTool
```

## Parameters

### -Tools

Tool names with optional versions (e.g., nodejs 18.0.0, python 3.11).


## Examples

### Example 1

`powershell
Install-AsdfTool nodejs 18.0.0
        Installs Node.js 18.0.0.
``

### Example 2

`powershell
Install-AsdfTool python 3.11
        Installs Python 3.11.
``

## Aliases

This function has the following aliases:

- `asdfadd` - Installs tools using asdf.
- `asdfinstall` - Installs tools using asdf.


## Source

Defined in: ..\profile.d\asdf.ps1
