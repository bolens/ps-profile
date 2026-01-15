# Tail-KubeLogs

## Synopsis

Tails logs from Kubernetes pods.

## Description

Uses stern (if available) or kubectl to tail logs from multiple pods matching a pattern. Stern provides better multi-pod log aggregation.

## Signature

```powershell
Tail-KubeLogs
```

## Parameters

### -Pattern

Pod name pattern to match (supports regex with stern).

### -Namespace

Kubernetes namespace. Defaults to current namespace.

### -Container

Optional container name to filter logs.

### -Follow

Follow log output (like tail -f). Defaults to true.


## Outputs

System.String. Log output stream.


## Examples

### Example 1

`powershell
Tail-KubeLogs -Pattern "my-app"
        
        Tails logs from all pods matching "my-app".
``

### Example 2

`powershell
Tail-KubeLogs -Pattern "nginx" -Namespace "production" -Container "web"
        
        Tails logs from nginx pods in production namespace, container web.
``

## Source

Defined in: ..\profile.d\kubernetes-enhanced.ps1
