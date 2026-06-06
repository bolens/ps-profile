# Test-Fragment

## Synopsis

Tests a fragment by loading it with minimal dependencies.

## Description

Loads a fragment with only bootstrap and env dependencies for isolated testing.

## Signature

```powershell
Test-Fragment
```

## Parameters

### -FragmentName

Name of the fragment to test (without .ps1 extension).


## Examples

### Example 1

`powershell
Test-Fragment -FragmentName 'files'
    Loads bootstrap, env, and files fragments for testing.
``

## Source

Defined in: ../profile.d/utilities-modules/system/utilities-profile.ps1
