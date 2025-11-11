# Get-ProfileFragment

## Synopsis

Gets the status of profile fragments.

## Description

Lists all profile fragments and their enabled/disabled status.

## Signature

```powershell
Get-ProfileFragment
```

## Parameters

### -FragmentName

Optional. Filter by specific fragment name.

### -DisabledOnly

Show only disabled fragments.

### -EnabledOnly

Show only enabled fragments.


## Examples

### Example 1

`powershell
Get-ProfileFragment
``

### Example 2

`powershell
Get-ProfileFragment -DisabledOnly
``

## Source

Defined in: profile.d\00-bootstrap.ps1
