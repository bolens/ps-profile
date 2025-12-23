# Get-KubectlResource

## Synopsis

Gets Kubernetes resources.

## Description

Wrapper for kubectl get command.

## Signature

```powershell
Get-KubectlResource
```

## Parameters

### -Arguments

Arguments to pass to kubectl get.


## Examples

### Example 1

`powershell
Get-KubectlResource pods
``

### Example 2

`powershell
Get-KubectlResource pods -n default
``

## Aliases

This function has the following aliases:

- `kg` - Gets Kubernetes resources.


## Source

Defined in: ..\profile.d\17-kubectl.ps1
