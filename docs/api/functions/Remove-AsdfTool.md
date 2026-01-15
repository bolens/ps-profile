# Remove-AsdfTool

## Synopsis

Uninstalls tools from asdf.

## Description

Removes installed tool versions.

## Signature

```powershell
Remove-AsdfTool
```

## Parameters

### -Tool

Tool name.

### -Version

Version to uninstall.


## Examples

### Example 1

`powershell
Remove-AsdfTool nodejs 18.0.0
        Uninstalls Node.js 18.0.0.
``

## Aliases

This function has the following aliases:

- `asdfremove` - Uninstalls tools from asdf.
- `asdfuninstall` - Uninstalls tools from asdf.


## Source

Defined in: ..\profile.d\asdf.ps1
