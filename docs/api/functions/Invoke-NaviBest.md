# Invoke-NaviBest

## Synopsis

Finds the best matching command from navi cheatsheets.

## Description

Searches navi cheatsheets and returns the best matching command. If a query is provided, uses it for searching.

## Signature

```powershell
Invoke-NaviBest
```

## Parameters

### -Query

Optional search text used to select the best matching cheatsheet entry.


## Examples

### Example 1

`powershell
Invoke-NaviBest -Query 'find files'
.PARAMETER Query
    Optional search text used to select the best matching cheatsheet entry.
``

## Aliases

This function has the following aliases:

- `navib` - Finds the best matching command from navi cheatsheets.


## Source

Defined in: ../profile.d/navi.ps1
