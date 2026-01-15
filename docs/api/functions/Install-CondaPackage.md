# Install-CondaPackage

## Synopsis

Installs packages using conda.

## Description

Installs packages. Supports environment specification with -n/--name.

## Signature

```powershell
Install-CondaPackage
```

## Parameters

### -Packages

Package names to install.

### -Environment

Environment name to install into (-n/--name).

### -Channel

Channel to install from (-c/--channel).


## Examples

### Example 1

`powershell
Install-CondaPackage numpy
        Installs numpy in the current environment.
``

### Example 2

`powershell
Install-CondaPackage numpy -Environment myenv
        Installs numpy in the specified environment.
``

## Aliases

This function has the following aliases:

- `conda-add` - Installs packages using conda.
- `conda-install` - Installs packages using conda.


## Source

Defined in: ..\profile.d\conda.ps1
