# Get-KubeResources

## Synopsis

Gets Kubernetes resource information.

## Description

Retrieves detailed information about Kubernetes resources using kubectl. Supports different output formats and resource types.

## Signature

```powershell
Get-KubeResources
```

## Parameters

### -ResourceType

Kubernetes resource type (e.g., pods, services, deployments).

### -ResourceName

Optional specific resource name.

### -Namespace

Kubernetes namespace. Defaults to current namespace.

### -OutputFormat

Output format: wide, yaml, json. Defaults to wide.


## Outputs

System.String. Resource information in the specified format.


## Examples

### Example 1

`powershell
Get-KubeResources -ResourceType "pods"
        
        Lists all pods in the current namespace.
``

### Example 2

`powershell
Get-KubeResources -ResourceType "deployments" -Namespace "production" -OutputFormat "yaml"
        
        Gets deployments in production namespace as YAML.
``

## Source

Defined in: ..\profile.d\kubernetes-enhanced.ps1
