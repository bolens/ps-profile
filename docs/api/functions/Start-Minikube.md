# Start-Minikube

## Synopsis

Starts a Minikube Kubernetes cluster.

## Description

Starts a local Minikube Kubernetes cluster with optional configuration. Supports different drivers and profile management.

## Signature

```powershell
Start-Minikube
```

## Parameters

### -Profile

Minikube profile name. Defaults to minikube.

### -Driver

Minikube driver: docker, hyperv, virtualbox, etc.

### -Status

Check Minikube status instead of starting.


## Outputs

System.String. Minikube status or startup output.


## Examples

### Example 1

`powershell
Start-Minikube
        
        Starts Minikube cluster with default settings.
``

### Example 2

`powershell
Start-Minikube -Profile "dev" -Driver "docker"
        
        Starts Minikube cluster with custom profile and driver.
``

## Source

Defined in: ..\profile.d\kubernetes-enhanced.ps1
