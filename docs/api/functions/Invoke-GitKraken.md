# Invoke-GitKraken

## Synopsis

Launches GitKraken GUI.

## Description

Opens GitKraken, a cross-platform Git GUI client, in the current directory or specified repository path.

## Signature

```powershell
Invoke-GitKraken
```

## Parameters

### -RepositoryPath

Path to the Git repository. Defaults to current directory.


## Examples

### Example 1

`powershell
Invoke-GitKraken
        
        Opens GitKraken in the current directory.
``

### Example 2

`powershell
Invoke-GitKraken -RepositoryPath "C:\Projects\MyRepo"
        
        Opens GitKraken for the specified repository.
``

## Aliases

This function has the following aliases:

- `gitkraken` - Launches GitKraken GUI.


## Source

Defined in: ..\profile.d\git-enhanced.ps1
