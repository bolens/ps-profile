# Set-KubeNamespace

## Synopsis

Switches the active Kubernetes namespace.

## Description

Changes the active namespace using kubens (if available) or kubectl. Lists available namespaces if no namespace is specified.

## Signature

```powershell
Set-KubeNamespace
```

## Parameters

### -Namespace

Name of the namespace to switch to. If not specified, lists available namespaces.

### -List

List all available namespaces instead of switching.


## Outputs

System.String. Namespace information or list of namespaces.


## Examples

### Example 1

`powershell
Set-KubeNamespace -List
        
        Lists all available Kubernetes namespaces.
``

### Example 2

`powershell
Set-KubeNamespace -Namespace "production"
        
        Switches to the specified namespace.
``

## Source

Defined in: ..\profile.d\kubernetes-enhanced.ps1
