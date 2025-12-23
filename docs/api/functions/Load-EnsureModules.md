# Load-EnsureModules

## Synopsis

Loads modules for a specific Ensure function from the registry.

## Description

Loads all modules associated with an Ensure function from the module registry. This enables deferred loading - modules are only loaded when their Ensure function is called.

## Signature

```powershell
Load-EnsureModules
```

## Parameters

### -EnsureFunctionName

The name of the Ensure function (e.g., 'Ensure-FileConversion-Data').

### -BaseDir

The base directory for resolving module paths (typically $PSScriptRoot).


## Examples

### Example 1

`powershell
Load-EnsureModules -EnsureFunctionName 'Ensure-FileConversion-Data' -BaseDir $PSScriptRoot
``

## Source

Defined in: ..\profile.d\02-files-module-registry.ps1
