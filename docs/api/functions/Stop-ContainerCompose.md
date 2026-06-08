# Stop-ContainerCompose

## Synopsis

Stops container services using compose (Docker-first).

## Description

Runs 'compose down' using the available container engine, preferring Docker over Podman. Automatically detects and uses docker compose, docker-compose, podman compose, or podman-compose.

## Signature

```powershell
Stop-ContainerCompose
```

## Parameters

### -args

Additional arguments forwarded to compose down.


## Examples

### Example 1

`powershell
Stop-ContainerCompose
``

## Aliases

This function has the following aliases:

- `dcd` - Stops container services using compose (Docker-first).


## Source

Defined in: ../profile.d/container-modules/container-compose.ps1
