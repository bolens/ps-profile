# Describe-KubeResource

## Synopsis

Gets detailed description of Kubernetes resources.

## Description

Provides enhanced describe functionality for Kubernetes resources with better formatting and filtering options.

## Signature

```powershell
Describe-KubeResource
```

## Parameters

### -ResourceType

Kubernetes resource type (e.g., pods, services, deployments).

### -ResourceName

Resource name. If not specified, describes all resources of the type.

### -Namespace

Kubernetes namespace. Defaults to current namespace.

### -ShowEvents

Include events in the description (default: true).

### -ShowYaml

Show resource YAML instead of describe output.


## Outputs

System.String. Resource description or YAML.


## Examples

### Example 1

`powershell
Describe-KubeResource -ResourceType "pods" -ResourceName "my-pod"
        
        Describes the my-pod pod.
``

### Example 2

`powershell
Describe-KubeResource -ResourceType "deployments" -Namespace "production" -ShowYaml
        
        Shows YAML for all deployments in production namespace.
``

## Source

Defined in: ..\profile.d\kubernetes-enhanced.ps1
