# Install-NpmPackage

## Synopsis

Installs packages using npm.

## Description

Installs packages as dependencies. Supports --save-dev, --save-prod, --global flags.

## Signature

```powershell
Install-NpmPackage
```

## Parameters

### -Packages

Package names to install.

### -Dev

Install as dev dependency (--save-dev).

### -Global

Install globally (--global).

### -Prod

Install as production dependency (--save-prod, default).


## Examples

### Example 1

`powershell
Install-NpmPackage express
        Installs express as a production dependency.
``

### Example 2

`powershell
Install-NpmPackage typescript -Dev
        Installs typescript as a dev dependency.
``

### Example 3

`powershell
Install-NpmPackage nodemon -Global
        Installs nodemon globally.
``

## Aliases

This function has the following aliases:

- `npmadd` - Installs packages using npm.
- `npminstall` - Installs packages using npm.


## Source

Defined in: ..\profile.d\npm.ps1
