# Write-SubModuleError

## Synopsis

Provides consistent error handling when loading sub-modules.

## Description

Helper function for consistent error handling when loading sub-modules. Uses Write-ProfileError if available, otherwise falls back to Write-Warning. Only outputs errors when PS_PROFILE_DEBUG environment variable is set.

## Signature

```powershell
Write-SubModuleError
```

## Parameters

### -ErrorRecord

The error record to report.

### -ModuleName

The name of the module that failed to load.


## Examples

### Example 1

`powershell
try {
        . (Join-Path $dir 'module.ps1')
    }
    catch {
        Write-SubModuleError -ErrorRecord $_ -ModuleName 'module.ps1'
    }

    Reports an error when loading a sub-module fails.
``

## Source

Defined in: ..\profile.d\02-files.ps1
