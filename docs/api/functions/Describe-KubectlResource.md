# Describe-KubectlResource

## Synopsis

Describes Kubernetes resources.

## Description

Wrapper for kubectl describe command.

## Signature

```powershell
Describe-KubectlResource
```

## Parameters

### -Arguments

Arguments to pass to kubectl describe.


## Examples

### Example 1

`powershell
Describe-KubectlResource pod my-pod
``

### Example 2

`powershell
Describe-KubectlResource pod my-pod -n default
``

## Aliases

This function has the following aliases:

- `kd` - Describes Kubernetes resources.


## Source

Defined in: ..\profile.d\17-kubectl.ps1
