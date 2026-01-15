# Clear-ChocoCache

## Synopsis

Cleans up Chocolatey cache.

## Description

Removes cached package files from Chocolatey's download cache. This helps free up disk space by removing downloaded installers. Note: Chocolatey doesn't have a built-in command to remove old package versions from the lib directory. Old versions can be manually removed from C:\ProgramData\chocolatey\lib if needed.

## Signature

```powershell
Clear-ChocoCache
```

## Parameters

### -Yes

Auto-confirm all prompts.


## Examples

### Example 1

`powershell
Clear-ChocoCache
        Cleans the download cache.
``

## Aliases

This function has the following aliases:

- `choclean` - Cleans up Chocolatey cache.
- `chocleanup` - Cleans up Chocolatey cache.


## Source

Defined in: ..\profile.d\chocolatey.ps1
