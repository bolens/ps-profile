# New-HatchEnvironment

## Synopsis

Creates a virtual environment using Hatch.

## Description

Creates a virtual environment for the project.

## Signature

```powershell
New-HatchEnvironment
```

## Parameters

### -Name

Environment name (optional).


## Examples

### Example 1

`powershell
New-HatchEnvironment
        Creates default environment.
``

### Example 2

`powershell
New-HatchEnvironment -Name dev
        Creates named environment.
``

## Aliases

This function has the following aliases:

- `hatchenv` - Creates a virtual environment using Hatch.


## Source

Defined in: ..\profile.d\hatch.ps1
