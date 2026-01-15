# Invoke-PnpmInstall

## Synopsis

Installs packages using pnpm.

## Description

Adds packages as dependencies to the project using pnpm. Supports -D (dev) and -g (global) flags.

## Signature

```powershell
Invoke-PnpmInstall
```

## Parameters

### -Packages

Package names to install.

### -Dev

Install as dev dependency (-D).

### -Global

Install globally (-g).


## Examples

### Example 1

`powershell
Invoke-PnpmInstall express
        Installs express as a production dependency.
``

### Example 2

`powershell
Invoke-PnpmInstall typescript -Dev
        Installs typescript as a dev dependency.
``

### Example 3

`powershell
Invoke-PnpmInstall nodemon -Global
        Installs nodemon globally.
``

## Aliases

This function has the following aliases:

- `pnadd` - Installs packages using pnpm.


## Source

Defined in: ..\profile.d\pnpm.ps1
