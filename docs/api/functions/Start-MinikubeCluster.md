# Start-MinikubeCluster

## Synopsis

Starts a Minikube cluster.

## Description

Wrapper for minikube start command.

## Signature

```powershell
Start-MinikubeCluster
```

## Parameters

### -Arguments

Arguments to pass to minikube start.


## Examples

### Example 1

`powershell
Start-MinikubeCluster
``

### Example 2

`powershell
Start-MinikubeCluster --driver=docker
``

## Aliases

This function has the following aliases:

- `minikube-start` - Starts a Minikube cluster.


## Source

Defined in: ..\profile.d\21-kube.ps1
