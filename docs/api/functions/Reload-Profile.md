# Reload-Profile

## Synopsis

Reloads the PowerShell profile.

## Description

Dots-sources the current profile file to reload all functions and settings.

## Signature

```powershell
Reload-Profile
```

## Parameters

### -Fast

Enables fast reload mode, skipping expensive operations like update checks and git status. Automatically enabled if PS_PROFILE_FAST_RELOAD or PS_PROFILE_DEV_MODE is set.


## Examples

### Example 1

`powershell
Reload-Profile
    Reloads the profile normally.
``

### Example 2

`powershell
Reload-Profile -Fast
    Reloads the profile in fast mode, skipping expensive operations.
``

## Aliases

This function has the following aliases:

- `reload` - Reloads the PowerShell profile.


## Source

Defined in: ../profile.d/utilities-modules/system/utilities-profile.ps1
