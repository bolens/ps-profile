# Clear-ContainerSystem

## Synopsis

Prunes unused container system resources (Docker-first).

## Description

Runs 'system prune -f' using the available container engine, preferring Docker over Podman. Removes unused containers, networks, images, and build cache.

## Signature

```powershell
Clear-ContainerSystem
```

## Parameters

### -args

Additional arguments forwarded to system prune -f.


## Examples

### Example 1

`powershell
Clear-ContainerSystem
``

## Aliases

This function has the following aliases:

- `dprune` - Prunes unused container system resources (Docker-first).


## Source

Defined in: ../profile.d/container-modules/container-compose.ps1
