# Invoke-Jujutsu

## Synopsis

Runs Jujutsu version control commands.

## Description

Executes Jujutsu (jj) commands. Jujutsu is a Git-compatible version control system with a different mental model.

## Signature

```powershell
Invoke-Jujutsu
```

## Parameters

### -Arguments

Arguments to pass to jj.


## Outputs

System.String. Output from Jujutsu command.


## Examples

### Example 1

`powershell
Invoke-Jujutsu init
        
        Initializes a new Jujutsu repository.
``

### Example 2

`powershell
Invoke-Jujutsu status
        
        Shows Jujutsu repository status.
``

## Aliases

This function has the following aliases:

- `jj` - Runs Jujutsu version control commands.


## Source

Defined in: ..\profile.d\git-enhanced.ps1
