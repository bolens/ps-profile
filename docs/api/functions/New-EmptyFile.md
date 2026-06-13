# New-EmptyFile

## Synopsis

Creates empty files or updates file timestamps.

## Description

Creates new empty files at the specified paths, or updates the last write time of existing files (Unix touch behavior).

## Signature

```powershell
New-EmptyFile
```

## Parameters

### -Path

One or more file paths to create or touch.

### -LiteralPath

Literal file paths to create or touch without wildcard expansion.


## Examples

### Example 1

```powershell
New-EmptyFile ./notes.txt
```

### Example 2

```powershell
New-EmptyFile -LiteralPath 'C:\temp\marker.txt'
```

## Aliases

This function has the following aliases:

- `touch` - Creates empty files or updates file timestamps.


## Source

Defined in: ../profile.d/system/FileOperations.ps1
