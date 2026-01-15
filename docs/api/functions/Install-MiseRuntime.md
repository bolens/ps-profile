# Install-MiseRuntime

## Synopsis

Installs Mise runtimes and tools.

## Description

Installs runtime versions or tools using mise install.

## Signature

```powershell
Install-MiseRuntime
```

## Parameters

### -Runtimes

Runtime names and versions to install (e.g., 'nodejs@20', 'python@3.11').


## Examples

### Example 1

`powershell
Install-MiseRuntime nodejs@20
        Installs Node.js version 20.
``

### Example 2

`powershell
Install-MiseRuntime python@3.11,nodejs@20
        Installs multiple runtimes.
``

## Aliases

This function has the following aliases:

- `mise-add` - Installs Mise runtimes and tools.
- `mise-install` - Installs Mise runtimes and tools.


## Source

Defined in: ..\profile.d\mise.ps1
