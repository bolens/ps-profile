# ===============================================
# Container engine helper functions
# Engine detection and preference management
# ===============================================

<#
.SYNOPSIS
    Gets the preferred container engine (docker/podman) based on availability and user preference.
.DESCRIPTION
    Determines which container engine to use based on:
    1. User preference via $env:CONTAINER_ENGINE_PREFERENCE ('docker' or 'podman')
    2. Engine availability (checks if docker/podman are installed)
    3. Compose tool availability (checks docker-compose, podman-compose, and compose subcommands)
    4. Defaults to 'docker' if both are available and no preference is set
    
    Returns a hashtable with engine information including:
    - Engine: 'docker', 'podman', 'docker-compose', 'podman-compose', or $null
    - Available: $true if any engine is available
    - DockerAvailable: $true if docker is available
    - PodmanAvailable: $true if podman is available
    - DockerComposeAvailable: $true if docker-compose or docker compose is available
    - PodmanComposeAvailable: $true if podman-compose or podman compose is available
    - InstallationCommand: Installation command for missing engines
.EXAMPLE
    $engineInfo = Get-ContainerEnginePreference
    if (-not $engineInfo.Available) {
        Write-Host "Install a container engine: $($engineInfo.InstallationCommand)"
    }
.OUTPUTS
    System.Collections.Hashtable
    Hashtable with Engine, Available, DockerAvailable, PodmanAvailable, and InstallationCommand keys.
#>
function Get-ContainerEnginePreference {
    # Return cached result if available (prevents recursion)
    if ($script:__ContainerEnginePreference) {
        return $script:__ContainerEnginePreference
    }
    
    # Check availability of all container tools
    $dockerAvailable = Test-CachedCommand docker
    $dockerComposeCmdAvailable = Test-CachedCommand docker-compose
    $podmanAvailable = Test-CachedCommand podman
    $podmanComposeCmdAvailable = Test-CachedCommand podman-compose
    
    # Check compose subcommand support
    $dockerComposeSubcommand = $false
    $podmanComposeSubcommand = $false
    
    if ($dockerAvailable) {
        try {
            $versionOutput = & docker compose version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $dockerComposeSubcommand = $true
            }
        }
        catch {
            # Ignore errors
        }
    }
    
    if ($podmanAvailable) {
        try {
            $versionOutput = & podman compose version 2>&1
            if ($LASTEXITCODE -eq 0) {
                $podmanComposeSubcommand = $true
            }
        }
        catch {
            # Ignore errors
        }
    }
    
    $dockerComposeAvailable = $dockerComposeCmdAvailable -or $dockerComposeSubcommand
    $podmanComposeAvailable = $podmanComposeCmdAvailable -or $podmanComposeSubcommand
    
    $anyAvailable = $dockerAvailable -or $podmanAvailable -or $dockerComposeAvailable -or $podmanComposeAvailable
    
    # Build installation command recommendations
    $installCommands = @()
    if (-not $dockerAvailable) {
        $installCommands += 'scoop install docker'
    }
    if (-not $podmanAvailable) {
        $installCommands += 'scoop install podman'
    }
    $installationCommand = if ($installCommands.Count -gt 0) {
        $installCommands -join ' or '
    }
    else {
        $null
    }
    
    # Check user preference
    $preference = if ($env:CONTAINER_ENGINE_PREFERENCE) {
        $env:CONTAINER_ENGINE_PREFERENCE.ToLower()
    }
    else {
        'auto'
    }
    
    # Determine engine based on preference and availability
    $selectedEngine = $null
    if ($preference -eq 'docker' -and $dockerAvailable) {
        if ($dockerComposeSubcommand) {
            $selectedEngine = 'docker'
        }
        elseif ($dockerComposeCmdAvailable) {
            $selectedEngine = 'docker-compose'
        }
        else {
            $selectedEngine = 'docker'
        }
    }
    elseif ($preference -eq 'podman' -and $podmanAvailable) {
        if ($podmanComposeSubcommand) {
            $selectedEngine = 'podman'
        }
        elseif ($podmanComposeCmdAvailable) {
            $selectedEngine = 'podman-compose'
        }
        else {
            $selectedEngine = 'podman'
        }
    }
    elseif ($preference -eq 'auto') {
        if ($dockerAvailable -and $dockerComposeSubcommand) {
            $selectedEngine = 'docker'
        }
        elseif ($dockerComposeCmdAvailable) {
            $selectedEngine = 'docker-compose'
        }
        elseif ($podmanAvailable -and $podmanComposeSubcommand) {
            $selectedEngine = 'podman'
        }
        elseif ($podmanComposeCmdAvailable) {
            $selectedEngine = 'podman-compose'
        }
        elseif ($dockerAvailable) {
            $selectedEngine = 'docker'
        }
        elseif ($podmanAvailable) {
            $selectedEngine = 'podman'
        }
    }
    
    $result = @{
        Engine                  = $selectedEngine
        Available               = $anyAvailable
        DockerAvailable         = $dockerAvailable
        PodmanAvailable         = $podmanAvailable
        DockerComposeAvailable  = $dockerComposeAvailable
        PodmanComposeAvailable  = $podmanComposeAvailable
        DockerComposeSubcommand = $dockerComposeSubcommand
        PodmanComposeSubcommand = $podmanComposeSubcommand
        InstallationCommand     = $installationCommand
    }
    
    # Cache the result to prevent recursion
    $script:__ContainerEnginePreference = $result
    return $result
}

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
    # Use Test-CachedCommand for efficient command checks that avoid module autoload
    $hasDocker = Test-CachedCommand docker
    $hasDockerComposeCmd = Test-CachedCommand docker-compose
    $hasPodman = Test-CachedCommand podman
    $hasPodmanComposeCmd = Test-CachedCommand podman-compose
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
    # Use Test-CachedCommand for efficient command checks that avoid module autoload
    $hasDocker = Test-CachedCommand docker
    $hasDockerComposeCmd = Test-CachedCommand docker-compose
    $hasPodman = Test-CachedCommand podman
    $hasPodmanComposeCmd = Test-CachedCommand podman-compose

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

