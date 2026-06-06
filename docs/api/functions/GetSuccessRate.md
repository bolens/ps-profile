# GetSuccessRate

## Synopsis

Loads multiple fragment modules with batch optimization.

## Description

Loads multiple modules efficiently, validating all paths first, then loading sequentially (respecting dependencies if specified).

## Signature

```powershell
GetSuccessRate
```

## Parameters

### -FragmentRoot

Root directory of fragments.

### -Modules

Array of hashtables, each containing ModulePath, Context, and optional Dependencies.

### -StopOnError

If specified, stops loading on first error.


## Examples

### Example 1

`powershell
Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules @(
        @{ ModulePath = @('dev-tools-modules', 'build', 'build-tools.ps1'); Context = 'build-tools' },
        @{ ModulePath = @('dev-tools-modules', 'build', 'testing-frameworks.ps1'); Context = 'testing' }
    )
``

## Source

Defined in: ../profile.d/bootstrap/ModuleLoading.ps1
