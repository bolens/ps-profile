# Import-FragmentModule

## Synopsis

Loads a module file with consistent error handling.

## Description

Dot-sources a module file from the specified directory with standardized error handling. This reduces code duplication when loading multiple modules.

## Signature

```powershell
Import-FragmentModule
```

## Parameters

### -ModuleDir

The directory containing the module file.

### -ModuleFile

The name of the module file to load (e.g., 'module.ps1').

### -ModuleName

Optional display name for the module (used in error messages). Defaults to the ModuleFile name.


## Examples

### Example 1

`powershell
Import-FragmentModule -ModuleDir $helpersDir -ModuleFile 'helpers-xml.ps1'
    
    Loads the helpers-xml.ps1 module from the helpers directory.
``

## Source

Defined in: ..\profile.d\02-files.ps1
