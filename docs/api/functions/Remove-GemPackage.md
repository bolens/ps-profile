# Remove-GemPackage

## Synopsis

Removes RubyGems packages.

## Description

Removes gems. Supports --user-install flag for user-installed gems.

## Signature

```powershell
Remove-GemPackage
```

## Parameters

### -Packages

Gem names to remove.

### -User

Remove from user directory (--user-install).

### -Version

Specific version to remove (--version).


## Examples

### Example 1

`powershell
Remove-GemPackage rails
        Removes rails from global installation.
``

### Example 2

`powershell
Remove-GemPackage rails -User
        Removes rails from user directory.
``

## Aliases

This function has the following aliases:

- `gem-remove` - Removes RubyGems packages.
- `gem-uninstall` - Removes RubyGems packages.


## Source

Defined in: ..\profile.d\gem.ps1
