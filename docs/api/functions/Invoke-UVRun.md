# Invoke-UVRun

## Synopsis

Runs Python commands in temporary virtual environments using uv.

## Description

Executes Python commands with their dependencies automatically managed in isolated environments.

## Signature

```powershell
Invoke-UVRun
```

## Parameters

### -Command

Python module or script to run with uv run.

### -Args

Additional arguments passed after the command.


## Examples

### Example 1

```powershell
Invoke-UVRun -Command python -Args @('--version')
```

## Aliases

This function has the following aliases:

- `uvrun` - Runs Python commands in temporary virtual environments using uv.


## Source

Defined in: ../profile.d/uv.ps1
