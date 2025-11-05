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

No parameters.

## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `dcl` - Shows container logs using compose (Docker-first).

## Source

Defined in: profile.d\22-containers.ps1
