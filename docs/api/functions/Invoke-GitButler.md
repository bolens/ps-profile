# Invoke-GitButler

## Synopsis

Runs Git Butler workflow commands.

## Description

Executes Git Butler commands for managing Git workflows and operations. Git Butler is a modern Git workflow tool.

## Signature

```powershell
Invoke-GitButler
```

## Parameters

### -Arguments

Arguments to pass to gitbutler.


## Outputs

System.String. Output from Git Butler command.


## Examples

### Example 1

`powershell
Invoke-GitButler status
        
        Shows Git Butler status.
``

### Example 2

`powershell
Invoke-GitButler sync
        
        Syncs the repository with Git Butler.
``

## Aliases

This function has the following aliases:

- `gitbutler` - Runs Git Butler workflow commands.


## Source

Defined in: ..\profile.d\git-enhanced.ps1
