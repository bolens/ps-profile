# Clear-ContainerSystemPodman

## Synopsis

Prunes unused container system resources (Podman-first).

## Description

Runs 'system prune -f' using the available container engine, preferring Podman over Docker. Removes unused containers, networks, images, and build cache.

## Signature

```powershell
Clear-ContainerSystemPodman
```

## Parameters

### -args

Additional arguments forwarded to system prune -f.


## Examples

### Example 1

`powershell
Clear-ContainerSystemPodman
``

## Aliases

This function has the following aliases:

- `pprune` - Prunes unused container system resources (Podman-first).


## Source

Defined in: ../profile.d/container-modules/container-compose-podman.ps1
