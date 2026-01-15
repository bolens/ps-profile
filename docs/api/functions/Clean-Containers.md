# Clean-Containers

## Synopsis

Cleans up containers, images, and volumes.

## Description

Removes stopped containers, unused images, and optionally volumes. Works with both Docker and Podman.

## Signature

```powershell
Clean-Containers
```

## Parameters

### -RemoveVolumes

Also remove unused volumes.

### -RemoveAll

Remove all containers and images, not just unused ones.

### -PruneSystem

Prune the entire system (all unused resources).


## Outputs

System.String. Output from cleanup commands.


## Examples

### Example 1

`powershell
Clean-Containers
        
        Removes stopped containers and unused images.
``

### Example 2

`powershell
Clean-Containers -RemoveVolumes
        
        Also removes unused volumes.
``

### Example 3

`powershell
Clean-Containers -PruneSystem
        
        Prunes all unused system resources.
``

## Source

Defined in: ..\profile.d\containers-enhanced.ps1
