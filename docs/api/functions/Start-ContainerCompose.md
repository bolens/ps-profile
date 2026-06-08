# Start-ContainerCompose

## Synopsis

Starts container services using compose (Docker-first).

## Description

Runs 'compose up -d' using the available container engine, preferring Docker over Podman. Automatically detects and uses docker compose, docker-compose, podman compose, or podman-compose.

## Signature

```powershell
Start-ContainerCompose
```

## Parameters

### -args

Additional arguments forwarded to compose up -d.


## Examples

### Example 1

`powershell
Start-ContainerCompose
``

## Aliases

This function has the following aliases:

- `dcu` - Starts container services using compose (Docker-first).


## Source

Defined in: ../profile.d/container-modules/container-compose.ps1
