# Reload-Fragment

## Synopsis

Reloads a specific profile fragment.

## Description

Reloads a single fragment from profile.d/ without reloading the entire profile. Useful for testing changes to a specific fragment during development.

## Signature

```powershell
Reload-Fragment
```

## Parameters

### -FragmentName

Name of the fragment to reload (without .ps1 extension).

### -FragmentNames

Array of fragment names to reload.


## Examples

### Example 1

`powershell
Reload-Fragment -FragmentName 'files'
    Reloads the files.ps1 fragment.
``

### Example 2

`powershell
Reload-Fragment -FragmentName 'files','utilities'
    Reloads multiple fragments.
``

## Source

Defined in: ../profile.d/utilities-modules/system/utilities-profile.ps1
