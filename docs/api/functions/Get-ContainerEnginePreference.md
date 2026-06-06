# Get-ContainerEnginePreference

## Synopsis

Gets the preferred container engine (docker/podman) based on availability and user preference.

## Description

Determines which container engine to use based on: 1. User preference via $env:CONTAINER_ENGINE_PREFERENCE ('docker' or 'podman') 2. Engine availability (checks if docker/podman are installed) 3. Compose tool availability (checks docker-compose, podman-compose, and compose subcommands) 4. Defaults to 'docker' if both are available and no preference is set Returns a hashtable with engine information including: - Engine: 'docker', 'podman', 'docker-compose', 'podman-compose', or $null - Available: $true if any engine is available - DockerAvailable: $true if docker is available - PodmanAvailable: $true if podman is available - DockerComposeAvailable: $true if docker-compose or docker compose is available - PodmanComposeAvailable: $true if podman-compose or podman compose is available - InstallationCommand: Installation command for missing engines

## Signature

```powershell
Get-ContainerEnginePreference
```

## Parameters

No parameters.

## Outputs

System.Collections.Hashtable Hashtable with Engine, Available, DockerAvailable, PodmanAvailable, and InstallationCommand keys.


## Examples

### Example 1

`powershell
$engineInfo = Get-ContainerEnginePreference
    if (-not $engineInfo.Available) {
        Write-Host "Install a container engine: $($engineInfo.InstallationCommand)"
    }
``

## Source

Defined in: ../profile.d/container-modules/container-helpers.ps1
