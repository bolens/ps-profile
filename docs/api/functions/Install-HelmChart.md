# Install-HelmChart

## Synopsis

Installs Helm charts.

## Description

Wrapper for helm install command.

## Signature

```powershell
Install-HelmChart
```

## Parameters

### -Arguments

Arguments to pass to helm install.


## Examples

### Example 1

`powershell
Install-HelmChart my-release ./my-chart
``

### Example 2

`powershell
Install-HelmChart my-release bitnami/nginx
``

## Aliases

This function has the following aliases:

- `helm-install` - Installs Helm charts.


## Source

Defined in: ..\profile.d\helm.ps1
