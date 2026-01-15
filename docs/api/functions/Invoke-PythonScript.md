# Invoke-PythonScript

## Synopsis

Runs Python scripts and commands.

## Description

Wrapper function for the Python interpreter that provides consistent execution across different Python installations.

## Signature

```powershell
Invoke-PythonScript
```

## Parameters

### -Script

Python script file to execute (optional).

### -Arguments

Arguments to pass to Python or the script. Can be used multiple times or as an array.


## Outputs

System.String. Output from Python execution.


## Examples

### Example 1

`powershell
Invoke-PythonScript script.py
        Runs a Python script.
``

### Example 2

`powershell
Invoke-PythonScript -Arguments @('-c', 'print("Hello")')
        Runs a Python one-liner.
``

## Source

Defined in: ..\profile.d\lang-python.ps1
