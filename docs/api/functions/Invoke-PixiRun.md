# Invoke-PixiRun

## Synopsis

Runs commands in the pixi environment.

## Description

Executes commands within the pixi-managed environment with all dependencies available.

## Signature

```powershell
Invoke-PixiRun
```

## Parameters

### -Command

Command to run inside the pixi environment.

### -Args

Additional arguments forwarded to the command.


## Examples

### Example 1

```powershell
Invoke-PixiRun -Command python -Args @('script.py')
```

## Aliases

This function has the following aliases:

- `pxrun` - Runs commands in the pixi environment.


## Source

Defined in: ../profile.d/pixi.ps1
