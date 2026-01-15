# Invoke-Mage

## Synopsis

Runs mage build targets for Go projects.

## Description

Wrapper function for mage, a build tool for Go that uses magefiles (Go files) to define build targets instead of Makefiles.

## Signature

```powershell
Invoke-Mage
```

## Parameters

### -Target

Mage target to run (optional, lists targets if not specified).

### -Arguments

Additional arguments to pass to mage. Can be used multiple times or as an array.


## Outputs

System.String. Output from mage execution.


## Examples

### Example 1

`powershell
Invoke-Mage
        Lists available mage targets.
``

### Example 2

`powershell
Invoke-Mage build
        Runs the 'build' target.
``

### Example 3

`powershell
Invoke-Mage test -v
        Runs the 'test' target with verbose output.
``

## Aliases

This function has the following aliases:

- `mage` - Runs mage build targets for Go projects.


## Source

Defined in: ..\profile.d\lang-go.ps1
