# Install-PythonApp

## Synopsis

Installs Python applications using pipx.

## Description

Wrapper function for pipx, which installs Python applications in isolated environments. pipx is similar to npm's global install or cargo install.

## Signature

```powershell
Install-PythonApp
```

## Parameters

### -Packages

Package names to install. Can be used multiple times or as an array.

### -Arguments

Additional arguments to pass to pipx install. Can be used multiple times or as an array.


## Outputs

System.String. Output from pipx install execution.


## Examples

### Example 1

`powershell
Install-PythonApp black
        Installs black as a standalone application.
``

### Example 2

`powershell
Install-PythonApp pytest --include-deps
        Installs pytest with additional dependencies.
``

## Aliases

This function has the following aliases:

- `pipx-install` - Installs Python applications using pipx.


## Source

Defined in: ..\profile.d\lang-python.ps1
