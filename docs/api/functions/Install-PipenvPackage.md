# Install-PipenvPackage

## Synopsis

Installs packages using Pipenv.

## Description

Installs packages and adds them to Pipfile. Supports --dev flag.

## Signature

```powershell
Install-PipenvPackage
```

## Parameters

### -Packages

Package names to install.

### -Dev

Install as dev dependency (--dev).


## Examples

### Example 1

`powershell
Install-PipenvPackage requests
        Installs requests as production dependency.
``

### Example 2

`powershell
Install-PipenvPackage pytest -Dev
        Installs pytest as dev dependency.
``

## Aliases

This function has the following aliases:

- `pipenvadd` - Installs packages using Pipenv.
- `pipenvinstall` - Installs packages using Pipenv.


## Source

Defined in: ..\profile.d\pipenv.ps1
