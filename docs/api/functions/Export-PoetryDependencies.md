# Export-PoetryDependencies

## Synopsis

Exports Poetry dependencies to a requirements.txt file.

## Description

Creates a requirements.txt file containing all Poetry project dependencies with versions. This file can be used to restore packages on another system or after a reinstall. Requires poetry-plugin-export to be installed.

## Signature

```powershell
Export-PoetryDependencies
```

## Parameters

### -Path

Path to save the export file. Defaults to "requirements.txt" in current directory.

### -WithoutHashes

Exclude hash information from the export.

### -Dev

Include dev dependencies in the export.


## Examples

### Example 1

`powershell
Export-PoetryDependencies
        Exports dependencies to requirements.txt in current directory.
``

### Example 2

`powershell
Export-PoetryDependencies -Path "C:\backup\poetry-requirements.txt"
        Exports dependencies to a specific file.
``

### Example 3

`powershell
Export-PoetryDependencies -Dev
        Exports dependencies including dev dependencies.
``

## Aliases

This function has the following aliases:

- `poetrybackup` - Exports Poetry dependencies to a requirements.txt file.
- `poetryexport` - Exports Poetry dependencies to a requirements.txt file.


## Source

Defined in: ..\profile.d\poetry.ps1
