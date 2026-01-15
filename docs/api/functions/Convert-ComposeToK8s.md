# Convert-ComposeToK8s

## Synopsis

Converts Docker Compose files to Kubernetes manifests.

## Description

Uses kompose to convert docker-compose.yml files to Kubernetes deployment and service manifests.

## Signature

```powershell
Convert-ComposeToK8s
```

## Parameters

### -ComposeFile

Path to the docker-compose.yml file. Defaults to docker-compose.yml in current directory.

### -OutputPath

Directory where Kubernetes manifests will be saved. Defaults to current directory.

### -Format

Output format: yaml, json. Defaults to yaml.


## Outputs

System.String. Path to the output directory.


## Examples

### Example 1

`powershell
Convert-ComposeToK8s
        
        Converts docker-compose.yml in current directory to Kubernetes manifests.
``

### Example 2

`powershell
Convert-ComposeToK8s -ComposeFile "docker-compose.prod.yml" -OutputPath "k8s/"
        
        Converts the specified compose file and saves manifests to k8s/ directory.
``

## Source

Defined in: ..\profile.d\containers-enhanced.ps1
