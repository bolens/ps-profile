# Get-HelmReleases

## Synopsis

Lists Helm releases.

## Description

Wrapper for helm list command.

## Signature

```powershell
Get-HelmReleases
```

## Parameters

### -Arguments

Arguments to pass to helm list.


## Examples

### Example 1

`powershell
Get-HelmReleases
``

### Example 2

`powershell
Get-HelmReleases --all-namespaces
``

## Aliases

This function has the following aliases:

- `helm-list` - Lists Helm releases.


## Source

Defined in: ..\profile.d\52-helm.ps1
