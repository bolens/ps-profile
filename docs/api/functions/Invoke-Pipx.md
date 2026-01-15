# Invoke-Pipx

## Synopsis

Runs pipx-installed applications.

## Description

Wrapper function for pipx run, which runs Python applications in isolated environments without installing them globally.

## Signature

```powershell
Invoke-Pipx
```

## Parameters

### -Package

Package name to run.

### -Arguments

Arguments to pass to the application. Can be used multiple times or as an array.


## Outputs

System.String. Output from pipx run execution.


## Examples

### Example 1

`powershell
Invoke-Pipx black --check .
        Runs black in an isolated environment to check code formatting.
``

### Example 2

`powershell
Invoke-Pipx pytest tests/
        Runs pytest in an isolated environment.
``

## Aliases

This function has the following aliases:

- `pipx` - Runs pipx-installed applications.


## Source

Defined in: ..\profile.d\lang-python.ps1
