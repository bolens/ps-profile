# Test-ContainerEngine

## Synopsis

Tests for available container engines and compose tools.

## Description

Returns information about available container engines (Docker/Podman) and their compose capabilities. Checks for docker, docker-compose, podman, and podman-compose availability and compose subcommand support. Returns a PSCustomObject with Engine, Compose, and Preferred fields.

## Signature

```powershell
Test-ContainerEngine
```

## Parameters

No parameters.

## Examples

No examples provided.

## Source

Defined in: profile.d\24-container-utils.ps1
