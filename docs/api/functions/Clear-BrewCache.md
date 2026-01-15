# Clear-BrewCache

## Synopsis

Cleans up Homebrew cache and old package versions.

## Description

Removes old versions of installed formulae and cleans the download cache. This helps free up disk space by removing outdated package versions and cached downloads.

## Signature

```powershell
Clear-BrewCache
```

## Parameters

### -Formula

Specific formula to clean up (optional).

### -Scrub

Scrub the cache, removing downloads for even the latest versions of formulae.

### -Prune

Remove all cache files older than the specified number of days.

### -DryRun

Show what would be removed without actually deleting anything.


## Examples

### Example 1

`powershell
Clear-BrewCache
        Cleans up old versions and cache for all formulae.
``

### Example 2

`powershell
Clear-BrewCache -Formula git
        Cleans up old versions and cache for git formula only.
``

### Example 3

`powershell
Clear-BrewCache -Scrub
        Removes all cache files, including those for latest versions.
``

### Example 4

`powershell
Clear-BrewCache -Prune 30
        Removes cache files older than 30 days.
``

### Example 5

`powershell
Clear-BrewCache -DryRun
        Shows what would be removed without deleting.
``

## Aliases

This function has the following aliases:

- `brewclean` - Cleans up Homebrew cache and old package versions.
- `brewcleanup` - Cleans up Homebrew cache and old package versions.


## Source

Defined in: ..\profile.d\homebrew.ps1
