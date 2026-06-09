# Find-String

## Synopsis

Searches for patterns in files.

## Description

Searches for text patterns in files using Select-String.

## Signature

```powershell
Find-String
```

## Parameters

### -Pattern

Text or regex pattern to search for.

### -Path

File or directory path to search. Defaults to the current directory when omitted.


## Examples

### Example 1

```powershell
Find-String -Pattern 'TODO' -Path ./src
```

## Aliases

This function has the following aliases:

- `pgrep` - Searches for patterns in files.


## Source

Defined in: ../profile.d/system/TextSearch.ps1
