# Register-LanguageModule

## Synopsis

Registers a language module with standardized commands.

## Description

Creates a standardized set of functions and aliases for a language runtime. Handles version management, build commands, package management, and more.

## Signature

```powershell
Register-LanguageModule
```

## Parameters

### -LanguageName

Name of the language (e.g., 'Python', 'Go', 'Rust').

### -CommandName

Name of the CLI command (e.g., 'python', 'go', 'cargo').

### -VersionManager

Optional version manager command name (e.g., 'pyenv', 'nvm', 'rustup').

### -BuildCommand

Command for building projects (default: 'build').

### -TestCommand

Command for running tests (default: 'test').

### -RunCommand

Command for running projects (default: 'run').

### -PackageManager

Optional package manager command name (e.g., 'pip', 'npm', 'cargo').

### -CustomCommands

Hashtable of custom command names to script blocks.


## Outputs

System.Boolean. True if registration successful, false otherwise.


## Examples

### Example 1

`powershell
Register-LanguageModule -LanguageName 'Python' -CommandName 'python' `
            -VersionManager 'pyenv' -PackageManager 'pip' `
            -BuildCommand 'setup.py build' -TestCommand 'pytest'
        
        Registers Python language module with pyenv and pip support.
``

## Source

Defined in: ../profile.d/bootstrap/LanguageBase.ps1
