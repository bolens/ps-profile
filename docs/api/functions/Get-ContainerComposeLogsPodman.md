# Get-ContainerComposeLogsPodman

## Synopsis

Shows container logs using compose (Podman-first).

## Description

Runs 'compose logs -f' using the available container engine, preferring Podman over Docker. Automatically detects and uses podman compose, podman-compose, docker compose, or docker-compose.

## Signature

```powershell
Get-ContainerComposeLogsPodman
```

## Parameters

### -args

Additional arguments forwarded to compose logs -f.


## Examples

### Example 1

```powershell
Get-ContainerComposeLogsPodman -args @('--version')
```

## Aliases

This function has the following aliases:

- `pcl` - Shows container logs using compose (Podman-first).


## Source

Defined in: ../profile.d/container-modules/container-compose-podman.ps1
