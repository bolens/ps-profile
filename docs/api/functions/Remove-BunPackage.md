# Remove-BunPackage

## Synopsis

Removes packages using Bun.

## Description

Wrapper for bun remove command. Supports --global flag.

## Signature

```powershell
Remove-BunPackage
```

## Parameters

### -Packages

Package names to remove.

### -Global

Remove from global packages (--global).


## Examples

### Example 1

`powershell
Remove-BunPackage express
    Removes express from production dependencies.
``

### Example 2

`powershell
Remove-BunPackage typescript -Dev
    Removes typescript from dev dependencies.
``

### Example 3

`powershell
Remove-BunPackage nodemon -Global
    Removes nodemon from global packages.
``

## Aliases

This function has the following aliases:

- `bun-remove` - Removes packages using Bun.


## Source

Defined in: ..\profile.d\bun.ps1
