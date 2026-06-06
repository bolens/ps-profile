# Register-PackageManager

## Synopsis

Registers a package manager with standardized commands.

## Description

Creates a standardized set of functions for a package manager. Handles install, uninstall, list, update, and run commands.

## Signature

```powershell
Register-PackageManager
```

## Parameters

### -ManagerName

Name of the package manager (e.g., 'Npm', 'Pip', 'Cargo').

### -CommandName

Name of the CLI command (e.g., 'npm', 'pip', 'cargo').

### -InstallCommand

Command for installing packages (default: 'install').

### -UninstallCommand

Command for uninstalling packages (default: 'uninstall').

### -ListCommand

Command for listing packages (default: 'list').

### -UpdateCommand

Command for updating packages (default: 'update').

### -RunCommand

Command for running scripts (default: 'run').

### -LockFile

Optional lock file name (e.g., 'package-lock.json', 'Cargo.lock').

### -GlobalFlag

Flag for global installs (e.g., '-g' for npm, '--user' for pip).

### -CustomCommands

Hashtable of custom command names to script blocks.


## Outputs

System.Boolean. True if registration successful, false otherwise.


## Examples

### Example 1

`powershell
Register-PackageManager -ManagerName 'Npm' -CommandName 'npm' `
            -InstallCommand 'install' -GlobalFlag '-g' -LockFile 'package-lock.json'
        
        Registers npm package manager with standard commands.
``

## Source

Defined in: ../profile.d/bootstrap/PackageManagerBase.ps1
