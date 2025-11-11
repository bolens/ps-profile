# Disable-ProfileFragment

## Synopsis

Disables a profile fragment.

## Description

Adds a fragment to the disabled list, preventing it from being loaded on next profile reload.

## Signature

```powershell
Disable-ProfileFragment
```

## Parameters

### -FragmentName

The name of the fragment to disable (e.g., '11-git.ps1' or '11-git').


## Examples

### Example 1

`powershell
Disable-ProfileFragment -FragmentName '11-git'
``

## Source

Defined in: profile.d\00-bootstrap.ps1
