# Get-FragmentDependencies

## Synopsis

Gets dependencies declared in a fragment file.

## Description

Parses fragment file header comments to extract declared dependencies. Supports both #Requires -Fragment and # Dependencies: comment formats.

## Signature

```powershell
Get-FragmentDependencies
```

## Parameters

### -FragmentPath

Path to the fragment file to analyze.


## Examples

### Example 1

`powershell
Get-FragmentDependencies -FragmentPath 'profile.d/11-git.ps1'
``

## Source

Defined in: profile.d\00-bootstrap.ps1
