# Set-KubeContext

## Synopsis

Switches the active Kubernetes context.

## Description

Changes the active Kubernetes context using kubectx (if available) or kubectl. Lists available contexts if no context is specified.

## Signature

```powershell
Set-KubeContext
```

## Parameters

### -ContextName

Name of the context to switch to. If not specified, lists available contexts.

### -List

List all available contexts instead of switching.


## Outputs

System.String. Context information or list of contexts.


## Examples

### Example 1

`powershell
Set-KubeContext -List
        
        Lists all available Kubernetes contexts.
``

### Example 2

`powershell
Set-KubeContext -ContextName "my-context"
        
        Switches to the specified context.
``

## Source

Defined in: ..\profile.d\kubernetes-enhanced.ps1
