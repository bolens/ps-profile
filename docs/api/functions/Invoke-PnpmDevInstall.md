# Invoke-PnpmDevInstall

## Synopsis

Installs development packages using pnpm.

## Description

Adds packages as dev dependencies to the project using pnpm.

## Signature

```powershell
Invoke-PnpmDevInstall
```

## Parameters

### -Packages

Package names to add as development dependencies.


## Examples

### Example 1

`powershell
Invoke-PnpmDevInstall typescript eslint
.PARAMETER Packages
    Package names to add as development dependencies.
``

## Aliases

This function has the following aliases:

- `pndev` - Installs development packages using pnpm.


## Source

Defined in: ../profile.d/pnpm.ps1
