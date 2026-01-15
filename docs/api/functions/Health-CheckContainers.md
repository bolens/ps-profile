# Health-CheckContainers

## Synopsis

Performs health checks on all running containers.

## Description

Checks the health status of all running containers. Works with both Docker and Podman.

## Signature

```powershell
Health-CheckContainers
```

## Parameters

### -Container

Container name or ID. If not specified, checks all containers.

### -Format

Output format: table, json. Defaults to table.


## Outputs

System.Object. Health check results.


## Examples

### Example 1

`powershell
Health-CheckContainers
        
        Checks health of all running containers.
``

### Example 2

`powershell
Health-CheckContainers -Container "my-container" -Format json
        
        Checks health of my-container in JSON format.
``

## Source

Defined in: ..\profile.d\containers-enhanced.ps1
