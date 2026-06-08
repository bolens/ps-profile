# Invoke-UVTool

## Synopsis

Runs tools installed with UV.

## Description

Executes tools that were installed using uv tool install.

## Signature

```powershell
Invoke-UVTool
```

## Parameters

### -Arguments

Arguments forwarded to uv tool run.


## Examples

### Example 1

```powershell
Invoke-UVTool ruff --version
```

## Aliases

This function has the following aliases:

- `uvx` - Runs tools installed with UV.


## Source

Defined in: ../profile.d/uv.ps1
