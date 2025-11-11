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

No parameters.

## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `dprune` - Prunes unused container system resources (Docker-first).


## Source

Defined in: profile.d\22-containers.ps1
