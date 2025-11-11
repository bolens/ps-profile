# Visit-Fragment

## Synopsis

Calculates optimal fragment load order based on dependencies.

## Description

Analyzes fragments and their dependencies to determine the correct load order. Returns fragments sorted topologically to satisfy all dependencies.

## Signature

```powershell
Visit-Fragment
```

## Parameters

### -FragmentFiles

Array of fragment file info objects to analyze.

### -DisabledFragments

Array of disabled fragment names.


## Examples

### Example 1

`powershell
$fragments = Get-ChildItem profile.d/*.ps1
        $order = Get-FragmentLoadOrder -FragmentFiles $fragments
``

## Source

Defined in: profile.d\00-bootstrap.ps1
