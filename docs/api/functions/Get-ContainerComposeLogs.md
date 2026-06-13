# Get-ContainerComposeLogs

## Synopsis

Shows container logs using compose (Docker-first).

## Description

Runs 'compose logs -f' using the available container engine, preferring Docker over Podman. Automatically detects and uses docker compose, docker-compose, podman compose, or podman-compose.

## Signature

```powershell
Get-ContainerComposeLogs
```

## Parameters

### -args

Additional arguments forwarded to compose logs -f.


## Examples

### Example 1

```powershell
Get-ContainerComposeLogs -args @('--version')
```

## Aliases

This function has the following aliases:

- `dcl` - Shows container logs using compose (Docker-first).


## Source

Defined in: ../profile.d/container-modules/container-compose.ps1
