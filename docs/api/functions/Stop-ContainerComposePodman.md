# Stop-ContainerComposePodman

## Synopsis

Stops container services using compose (Podman-first).

## Description

Runs 'compose down' using the available container engine, preferring Podman over Docker. Automatically detects and uses podman compose, podman-compose, docker compose, or docker-compose.

## Signature

```powershell
Stop-ContainerComposePodman
```

## Parameters

### -args

Additional arguments forwarded to compose down.


## Examples

### Example 1

```powershell
Stop-ContainerComposePodman -args @('--version')
```

## Aliases

This function has the following aliases:

- `pcd` - Stops container services using compose (Podman-first).


## Source

Defined in: ../profile.d/container-modules/container-compose-podman.ps1
