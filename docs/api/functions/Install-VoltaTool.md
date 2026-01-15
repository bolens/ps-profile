# Install-VoltaTool

## Synopsis

Installs Node.js, npm, or Yarn using Volta.

## Description

Installs and pins tools to your project. Supports version specification.

## Signature

```powershell
Install-VoltaTool
```

## Parameters

### -Tools

Tool names with optional versions (e.g., node@18, npm@9, yarn@1.22).


## Examples

### Example 1

`powershell
Install-VoltaTool node@18
        Installs and pins Node.js 18.
``

### Example 2

`powershell
Install-VoltaTool node@18 npm@9
        Installs Node.js 18 and npm 9.
``

## Aliases

This function has the following aliases:

- `voltaadd` - Installs Node.js, npm, or Yarn using Volta.
- `voltainstall` - Installs Node.js, npm, or Yarn using Volta.


## Source

Defined in: ..\profile.d\volta.ps1
