# Apply-KubeManifests

## Synopsis

Applies multiple Kubernetes manifest files.

## Description

Applies Kubernetes manifests from files or directories. Supports recursive directory processing and dry-run mode.

## Signature

```powershell
Apply-KubeManifests
```

## Parameters

### -Path

Path to manifest file or directory containing manifests.

### -Recursive

Process directories recursively (default: false).

### -DryRun

Perform a dry-run without actually applying (default: false).

### -Namespace

Kubernetes namespace to apply to. Overrides namespace in manifests.

### -ServerSide

Use server-side apply (default: false).

### -Force

Force apply even if resources already exist (default: false).


## Outputs

System.String. Apply output from kubectl.


## Examples

### Example 1

`powershell
Apply-KubeManifests -Path "manifests/"
        
        Applies all manifests in the manifests directory.
``

### Example 2

`powershell
Apply-KubeManifests -Path "k8s/" -Recursive -DryRun
        
        Performs dry-run of all manifests recursively.
``

### Example 3

`powershell
Apply-KubeManifests -Path "deployment.yaml" -Namespace "production" -ServerSide
        
        Applies deployment.yaml to production namespace using server-side apply.
``

## Source

Defined in: ..\profile.d\kubernetes-enhanced.ps1
