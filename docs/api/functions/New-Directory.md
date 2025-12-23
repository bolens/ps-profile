# New-Directory

## Synopsis

Creates directories with Unix-like behavior.

## Description

Creates new directories at the specified paths. Supports -p flag to create parent directories and accepts multiple directory names as arguments, similar to Unix mkdir.

## Signature

```powershell
New-Directory
```

## Parameters

### -Path

One or more directory paths to create.

### -p

Create parent directories as needed (equivalent to -Parent).

### -Parent

Create parent directories as needed.


## Examples

### Example 1

`powershell
mkdir -p core fragment path
        Creates multiple directories: core, fragment, and path.
``

### Example 2

`powershell
mkdir -p parent/child/grandchild
        Creates the full directory path including parent directories.
``

## Aliases

This function has the following aliases:

- `mkdir` - Creates directories with Unix-like behavior.


## Source

Defined in: ..\profile.d\07-system.ps1
