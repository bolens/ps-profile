# Update-HelmRelease

## Synopsis

Upgrades Helm releases.

## Description

Wrapper for helm upgrade command.

## Signature

```powershell
Update-HelmRelease
```

## Parameters

### -Arguments

Arguments to pass to helm upgrade.


## Examples

### Example 1

`powershell
Update-HelmRelease my-release ./my-chart
``

### Example 2

`powershell
Update-HelmRelease my-release bitnami/nginx
``

## Aliases

This function has the following aliases:

- `helm-upgrade` - Upgrades Helm releases.


## Source

Defined in: ..\profile.d\52-helm.ps1
