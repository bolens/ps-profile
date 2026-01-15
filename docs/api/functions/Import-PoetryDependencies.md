# Import-PoetryDependencies

## Synopsis

Restores Poetry dependencies from a requirements.txt file.

## Description

Installs all packages listed in a requirements.txt file using pip. This is useful for restoring packages after a system reinstall or on a new machine. Note: Poetry projects should typically use 'poetry install' instead, but this function allows restoring from exported requirements.txt files.

## Signature

```powershell
Import-PoetryDependencies
```

## Parameters

### -Path

Path to the requirements.txt file to import. Defaults to "requirements.txt" in current directory.

### -NoDeps

Don't install dependencies (--no-deps flag for pip).


## Examples

### Example 1

`powershell
Import-PoetryDependencies
        Restores dependencies from requirements.txt in current directory.
``

### Example 2

`powershell
Import-PoetryDependencies -Path "C:\backup\poetry-requirements.txt"
        Restores dependencies from a specific file.
``

## Aliases

This function has the following aliases:

- `poetryimport` - Restores Poetry dependencies from a requirements.txt file.
- `poetryrestore` - Restores Poetry dependencies from a requirements.txt file.


## Source

Defined in: ..\profile.d\poetry.ps1
