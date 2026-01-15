# Install-GemPackage

## Synopsis

Installs RubyGems packages.

## Description

Installs gems. Supports --user-install for local installation.

## Signature

```powershell
Install-GemPackage
```

## Parameters

### -Packages

Gem names to install.

### -User

Install to user directory (--user-install).

### -Version

Specific version to install (--version).


## Examples

### Example 1

`powershell
Install-GemPackage rails
        Installs rails globally.
``

### Example 2

`powershell
Install-GemPackage rails -User
        Installs rails to user directory.
``

## Aliases

This function has the following aliases:

- `gem-add` - Installs RubyGems packages.
- `gem-install` - Installs RubyGems packages.


## Source

Defined in: ..\profile.d\gem.ps1
