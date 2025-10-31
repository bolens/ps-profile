# pprune

## Synopsis

Prunes unused container system resources (Podman-first).

## Description

Runs 'system prune -f' using the available container engine, preferring Podman over Docker.
        Removes unused containers, networks, images, and build cache.

## Signature

```powershell
pprune
```

No parameters.

## Examples

No examples provided.

## Source

Defined in: ..\profile.d\22-containers.ps1
