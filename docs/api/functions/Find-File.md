# Find-File

## Synopsis

Searches for files recursively.

## Description

Finds files by name pattern in the current directory and subdirectories.

## Signature

```powershell
Find-File
```

## Parameters

### -FilterArgs

Name filter arguments forwarded to Get-ChildItem -Recurse -Filter.


## Examples

### Example 1

```powershell
Find-File *.ps1
```

## Aliases

This function has the following aliases:

- `search` - Searches for files recursively.


## Source

Defined in: ../profile.d/system/FileOperations.ps1
