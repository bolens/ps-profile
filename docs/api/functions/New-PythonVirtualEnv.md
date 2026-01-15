# New-PythonVirtualEnv

## Synopsis

Creates a Python virtual environment.

## Description

Creates a Python virtual environment using the best available tool: - uv (if available) - fastest option - python -m venv (if available) - standard library option Falls back gracefully if neither is available.

## Signature

```powershell
New-PythonVirtualEnv
```

## Parameters

### -Path

Path where the virtual environment should be created. Defaults to '.venv' in the current directory.

### -PythonVersion

Python version to use (for uv only).


## Outputs

System.String. Output from virtual environment creation.


## Examples

### Example 1

`powershell
New-PythonVirtualEnv
        Creates a virtual environment in .venv.
``

### Example 2

`powershell
New-PythonVirtualEnv -Path 'venv'
        Creates a virtual environment in 'venv'.
``

## Aliases

This function has the following aliases:

- `pyvenv` - Creates a Python virtual environment.


## Source

Defined in: ..\profile.d\lang-python.ps1
