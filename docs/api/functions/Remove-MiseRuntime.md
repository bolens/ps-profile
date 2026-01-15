# Remove-MiseRuntime

## Synopsis

Removes Mise runtimes and tools.

## Description

Uninstalls runtime versions or tools using mise uninstall.

## Signature

```powershell
Remove-MiseRuntime
```

## Parameters

### -Runtimes

Runtime names and versions to remove (e.g., 'nodejs@20', 'python@3.11').


## Examples

### Example 1

`powershell
Remove-MiseRuntime nodejs@20
        Removes Node.js version 20.
``

## Aliases

This function has the following aliases:

- `mise-remove` - Removes Mise runtimes and tools.
- `mise-uninstall` - Removes Mise runtimes and tools.


## Source

Defined in: ..\profile.d\mise.ps1
