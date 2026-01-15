# Remove-NpmPackage

## Synopsis

Removes packages using npm.

## Description

Removes packages from dependencies. Supports --save-dev, --save-prod, --global flags.

## Signature

```powershell
Remove-NpmPackage
```

## Parameters

### -Packages

Package names to remove.

### -Dev

Remove from dev dependencies (--save-dev).

### -Global

Remove from global packages (--global).

### -Prod

Remove from production dependencies (--save-prod, default).


## Examples

### Example 1

`powershell
Remove-NpmPackage express
        Removes express from production dependencies.
``

### Example 2

`powershell
Remove-NpmPackage typescript -Dev
        Removes typescript from dev dependencies.
``

### Example 3

`powershell
Remove-NpmPackage nodemon -Global
        Removes nodemon from global packages.
``

## Aliases

This function has the following aliases:

- `npmremove` - Removes packages using npm.
- `npmuninstall` - Removes packages using npm.


## Source

Defined in: ..\profile.d\npm.ps1
