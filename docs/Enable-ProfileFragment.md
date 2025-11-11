# Enable-ProfileFragment

## Synopsis

Enables a profile fragment.

## Description

Removes a fragment from the disabled list, allowing it to be loaded on next profile reload.

## Signature

```powershell
Enable-ProfileFragment
```

## Parameters

### -FragmentName

The name of the fragment to enable (e.g., '11-git.ps1' or '11-git').


## Examples

### Example 1

`powershell
Enable-ProfileFragment -FragmentName '11-git'
``

## Source

Defined in: profile.d\00-bootstrap.ps1
