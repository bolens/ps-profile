# Start-ContainerComposePodman

## Synopsis

Starts container services using compose (Podman-first).

## Description

Runs 'compose up -d' using the available container engine, preferring Podman over Docker. Automatically detects and uses podman compose, podman-compose, docker compose, or docker-compose.

## Signature

```powershell
Start-ContainerComposePodman
```

## Parameters

### -args

Additional arguments forwarded to compose up -d.


## Examples

### Example 1

`powershell
Start-ContainerComposePodman
``

## Aliases

This function has the following aliases:

- `pcu` - Starts container services using compose (Podman-first).


## Source

Defined in: ../profile.d/container-modules/container-compose-podman.ps1
