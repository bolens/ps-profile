# Find-FileFuzzy

## Synopsis

Finds files using fzf fuzzy finder.

## Description

Recursively searches for files and uses fzf to interactively select one.

## Signature

```powershell
Find-FileFuzzy
```

## Parameters

### -Pattern

Optional pattern to filter files before passing to fzf.


## Examples

### Example 1

`powershell
Find-FileFuzzy
``

### Example 2

`powershell
Find-FileFuzzy -Pattern "\.ps1$"
``

## Aliases

This function has the following aliases:

- `ff` - Finds PowerShell commands using fzf fuzzy finder.


## Source

Defined in: ..\profile.d\19-fzf.ps1
