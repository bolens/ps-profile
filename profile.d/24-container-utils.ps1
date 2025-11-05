# ===============================================
# 24-container-utils.ps1
# Container engine helpers: report available engine and allow preference override
# ===============================================

<#
.SYNOPSIS
    Tests for available container engines and compose tools.
.DESCRIPTION
    Returns information about available container engines (Docker/Podman) and their compose capabilities.
    Checks for docker, docker-compose, podman, and podman-compose availability and compose subcommand support.
    Returns a PSCustomObject with Engine, Compose, and Preferred fields.
#>
function Test-ContainerEngine {
    $pref = ($env:CONTAINER_ENGINE_PREFERENCE) -as [string]
    # Use Test-HasCommand for efficient command checks that avoid module autoload
    $hasDocker = Test-HasCommand docker
    $hasDockerComposeCmd = Test-HasCommand docker-compose
    $hasPodman = Test-HasCommand podman
    $hasPodmanComposeCmd = Test-HasCommand podman-compose

    $engine = $null
    $compose = $null

    if ($pref -eq 'docker') { $engine = 'docker' }
    elseif ($pref -eq 'podman') { $engine = 'podman' }

    if (-not $engine) {
        if ($hasDocker) { $engine = 'docker' }
        elseif ($hasPodman) { $engine = 'podman' }
    }

    if ($engine -eq 'docker') {
        if ($hasDocker) { & docker compose version *> $null; if ($LASTEXITCODE -eq 0) { $compose = 'subcommand' } }
        if (-not $compose -and $hasDockerComposeCmd) { $compose = 'legacy' }
    }
    elseif ($engine -eq 'podman') {
        if ($hasPodman) { & podman compose version *> $null; if ($LASTEXITCODE -eq 0) { $compose = 'subcommand' } }
        if (-not $compose -and $hasPodmanComposeCmd) { $compose = 'legacy' }
    }

    [pscustomobject]@{
        Engine    = $engine
        Compose   = $compose
        Preferred = $pref
    }
}

<#
.SYNOPSIS
    Sets the preferred container engine for the session.
.DESCRIPTION
    Sets the CONTAINER_ENGINE_PREFERENCE environment variable to specify whether to prefer Docker or Podman.
    This affects which container engine is used by container-related functions in the profile.
#>
function Set-ContainerEnginePreference {
    param(
        [Parameter(Mandatory)][ValidateSet('docker', 'podman')] [string]$Engine
    )
    # Persist preference in environment for current session; users may set it in
    # their environment permanently via system/user env settings if desired.
    $env:CONTAINER_ENGINE_PREFERENCE = $Engine
    Write-Output "Container engine preference set to: $Engine"
}
