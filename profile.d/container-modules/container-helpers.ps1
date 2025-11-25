# ===============================================
# Container engine helper functions
# Engine detection and preference management
# ===============================================

<#
.SYNOPSIS
    Gets information about available container engines and compose tools.
.DESCRIPTION
    Returns cached information about available container engines (Docker/Podman) and their compose capabilities.
    Checks for docker, docker-compose, podman, and podman-compose availability and compose subcommand support.
#>
function Get-ContainerEngineInfo {
    # Return cached container engine info as a hashtable in script scope
    if ($script:__ContainerEngineInfo) { return $script:__ContainerEngineInfo }
    $info = [ordered]@{
        Preferred                 = $null
        Engine                    = $null
        SupportsComposeSubcommand = $false
        HasDockerComposeCmd       = $false
        HasPodmanComposeCmd       = $false
    }
    $pref = ($env:CONTAINER_ENGINE_PREFERENCE) -as [string]
    $info.Preferred = if ($pref) { $pref } else { $null }
    # Use Test-HasCommand for efficient command checks that avoid module autoload
    $hasDocker = Test-HasCommand docker
    $hasDockerComposeCmd = Test-HasCommand docker-compose
    $hasPodman = Test-HasCommand podman
    $hasPodmanComposeCmd = Test-HasCommand podman-compose
    $info.HasDockerComposeCmd = $hasDockerComposeCmd
    $info.HasPodmanComposeCmd = $hasPodmanComposeCmd
    # Test compose subcommand support once (only when docker/podman present)
    if ($hasDocker) {
        try {
            $versionOutput = & docker compose version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $info.SupportsComposeSubcommand = $true
            }
        }
        catch {
            if ($env:PS_PROFILE_DEBUG) {
                Write-Verbose "Failed to check docker compose version: $($_.Exception.Message)"
            }
        }
    }
    if ($pref -eq 'docker' -and $hasDocker) { $info.Engine = 'docker' }
    elseif ($pref -eq 'podman' -and $hasPodman) { $info.Engine = 'podman' }
    else {
        if ($hasDocker -and $info.SupportsComposeSubcommand) { $info.Engine = 'docker' }
        elseif ($hasDockerComposeCmd) { $info.Engine = 'docker-compose' }
        elseif ($hasPodman -and $info.SupportsComposeSubcommand) { $info.Engine = 'podman' }
        elseif ($hasPodmanComposeCmd) { $info.Engine = 'podman-compose' }
        else { $info.Engine = $null }
    }
    $script:__ContainerEngineInfo = $info
    return $info
}

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
        if ($hasDocker) {
            try {
                $versionOutput = & docker compose version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $compose = 'subcommand'
                }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Failed to check docker compose version: $($_.Exception.Message)"
                }
            }
        }
    }
    elseif ($engine -eq 'podman') {
        if ($hasPodman) {
            try {
                $versionOutput = & podman compose version 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $compose = 'subcommand'
                }
            }
            catch {
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "Failed to check podman compose version: $($_.Exception.Message)"
                }
            }
        }
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

