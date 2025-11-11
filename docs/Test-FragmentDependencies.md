# Test-FragmentDependencies

## Synopsis

Validates that fragment dependencies are satisfied.

## Description

Checks if all declared dependencies for a fragment exist and are enabled.

## Signature

```powershell
Test-FragmentDependencies
```

## Parameters

### -FragmentPath

Path to the fragment file to validate.

### -AvailableFragments

Hashtable of available fragments (name -> file info).

### -DisabledFragments

Array of disabled fragment names.


## Examples

### Example 1

`powershell
Test-FragmentDependencies -FragmentPath 'profile.d/11-git.ps1' -AvailableFragments $fragments
``

## Source

Defined in: profile.d\00-bootstrap.ps1
