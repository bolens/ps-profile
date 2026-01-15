# Install-NimblePackage

## Synopsis

Installs Nim packages.

## Description

Installs packages. Can install globally or locally (project-level).

## Signature

```powershell
Install-NimblePackage
```

## Parameters

### -Packages

Package names to install.

### -Global

Install globally (--global).


## Examples

### Example 1

`powershell
Install-NimblePackage jester
        Installs jester locally (if in a project) or globally.
``

### Example 2

`powershell
Install-NimblePackage jester -Global
        Installs jester globally.
``

## Aliases

This function has the following aliases:

- `nimble-add` - Installs Nim packages.
- `nimble-install` - Installs Nim packages.


## Source

Defined in: ..\profile.d\nimble.ps1
