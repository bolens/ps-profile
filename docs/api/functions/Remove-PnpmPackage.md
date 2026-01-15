# Remove-PnpmPackage

## Synopsis

Removes packages using pnpm.

## Description

Removes packages from dependencies. Supports --save-dev, --save-prod, --global flags.

## Signature

```powershell
Remove-PnpmPackage
```

## Parameters

### -Packages

Package names to remove.

### -Dev

Remove from dev dependencies (-D).

### -Global

Remove from global packages (-g).

### -Prod

Remove from production dependencies (default).


## Examples

### Example 1

`powershell
Remove-PnpmPackage express
        Removes express from production dependencies.
``

### Example 2

`powershell
Remove-PnpmPackage typescript -Dev
        Removes typescript from dev dependencies.
``

### Example 3

`powershell
Remove-PnpmPackage nodemon -Global
        Removes nodemon from global packages.
``

## Aliases

This function has the following aliases:

- `pnremove` - Removes packages using pnpm.
- `pnuninstall` - Removes packages using pnpm.


## Source

Defined in: ..\profile.d\pnpm.ps1
