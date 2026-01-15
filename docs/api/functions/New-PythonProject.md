# New-PythonProject

## Synopsis

Creates a new Python project structure.

## Description

Creates a new Python project with a basic structure including: - Project directory - README.md - .gitignore (Python-specific) - pyproject.toml or requirements.txt (depending on available tools)

## Signature

```powershell
New-PythonProject
```

## Parameters

### -Name

Project name (also used as directory name).

### -Path

Parent directory where the project should be created. Defaults to current directory.

### -UseUV

Use uv for project initialization (if available).


## Outputs

System.String. Path to the created project directory.


## Examples

### Example 1

`powershell
New-PythonProject myproject
        Creates a new Python project named 'myproject'.
``

### Example 2

`powershell
New-PythonProject myproject -Path 'C:\Projects' -UseUV
        Creates a project using uv in the specified path.
``

## Source

Defined in: ..\profile.d\lang-python.ps1
