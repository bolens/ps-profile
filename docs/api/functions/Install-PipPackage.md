# Install-PipPackage

## Synopsis

Installs Python packages using pip.

## Description

Installs packages. Supports --user (local) and --global (default) installation.

## Signature

```powershell
Install-PipPackage
```

## Parameters

### -Packages

Package names to install.

### -User

Install to user site-packages (--user).

### -Global

Install globally (default).


## Examples

### Example 1

`powershell
Install-PipPackage requests
        Installs requests globally.
``

### Example 2

`powershell
Install-PipPackage requests -User
        Installs requests to user directory.
``

## Aliases

This function has the following aliases:

- `pipadd` - Installs Python packages using pip.
- `pipinstall` - Installs Python packages using pip.


## Source

Defined in: ..\profile.d\pip.ps1
