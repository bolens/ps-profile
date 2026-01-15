# Invoke-GitTower

## Synopsis

Launches Git Tower GUI.

## Description

Opens Git Tower, a powerful Git GUI client, in the current directory or specified repository path.

## Signature

```powershell
Invoke-GitTower
```

## Parameters

### -RepositoryPath

Path to the Git repository. Defaults to current directory.


## Examples

### Example 1

`powershell
Invoke-GitTower
        
        Opens Git Tower in the current directory.
``

### Example 2

`powershell
Invoke-GitTower -RepositoryPath "C:\Projects\MyRepo"
        
        Opens Git Tower for the specified repository.
``

## Aliases

This function has the following aliases:

- `git-tower` - Launches Git Tower GUI.


## Source

Defined in: ..\profile.d\git-enhanced.ps1
