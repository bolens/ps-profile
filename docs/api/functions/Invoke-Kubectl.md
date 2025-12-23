# Invoke-Kubectl

## Synopsis

Executes kubectl with the specified arguments.

## Description

Wrapper function for kubectl that checks for command availability before execution.

## Signature

```powershell
Invoke-Kubectl
```

## Parameters

### -Arguments

Arguments to pass to kubectl.


## Examples

### Example 1

`powershell
Invoke-Kubectl version
``

### Example 2

`powershell
Invoke-Kubectl get pods
``

## Aliases

This function has the following aliases:

- `k` - Executes kubectl with the specified arguments.


## Source

Defined in: ..\profile.d\17-kubectl.ps1
