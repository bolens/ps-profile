# PortForward-KubeService

## Synopsis

Forwards ports from Kubernetes services or pods to local machine.

## Description

Creates port forwarding from Kubernetes resources to local ports. Supports both services and pods.

## Signature

```powershell
PortForward-KubeService
```

## Parameters

### -Resource

Resource name (pod or service).

### -ResourceType

Resource type: pod or service. Defaults to pod.

### -LocalPort

Local port to forward to. Defaults to same as remote port.

### -RemotePort

Remote port to forward from. Required for services.

### -Namespace

Kubernetes namespace. Defaults to current namespace.

### -Address

Local address to bind to. Defaults to localhost.


## Outputs

System.String. Port forwarding status or process information.


## Examples

### Example 1

`powershell
PortForward-KubeService -Resource "my-pod" -LocalPort 8080 -RemotePort 80
        
        Forwards local port 8080 to pod port 80.
``

### Example 2

`powershell
PortForward-KubeService -Resource "my-service" -ResourceType "service" -LocalPort 8080 -RemotePort 80
        
        Forwards local port 8080 to service port 80.
``

## Source

Defined in: ..\profile.d\kubernetes-enhanced.ps1
