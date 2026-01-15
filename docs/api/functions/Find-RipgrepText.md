# Find-RipgrepText

## Synopsis

Finds text using ripgrep with common options.

## Description

Wrapper for ripgrep with line numbers, hidden files, and case-insensitive search enabled.

## Signature

```powershell
Find-RipgrepText
```

## Parameters

### -Pattern

Text pattern to search for.


## Examples

### Example 1

`powershell
Find-RipgrepText -Pattern "function"
``

### Example 2

`powershell
Find-RipgrepText -Pattern "error"
``

## Aliases

This function has the following aliases:

- `rgf` - Finds text using ripgrep with common options.


## Source

Defined in: ..\profile.d\rg.ps1
