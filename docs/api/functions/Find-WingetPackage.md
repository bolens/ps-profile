# Find-WingetPackage

## Synopsis

Searches for winget packages.

## Description

Searches for available packages in the winget repository.

## Signature

```powershell
Find-WingetPackage
```

## Parameters

### -Query

Search query string.

### -Exact

Search for exact package ID match.

### -Source

Source to search in.


## Examples

### Example 1

`powershell
Find-WingetPackage git
        Searches for packages containing "git".
``

### Example 2

`powershell
Find-WingetPackage Git.Git -Exact
        Searches for exact package ID "Git.Git".
``

## Aliases

This function has the following aliases:

- `winget-find` - Searches for winget packages.
- `winget-search` - Searches for winget packages.


## Source

Defined in: ..\profile.d\winget.ps1
