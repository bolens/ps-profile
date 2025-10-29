# ===============================================
# 24-container-utils.ps1
# Container engine helpers: report available engine and allow preference override
# ===============================================

function Test-ContainerEngine {
    <#
    Returns a PSCustomObject with fields:
      - Engine: 'docker' | 'podman' | $null
      - Compose: 'subcommand' | 'legacy' | $null
      - Preferred: value of CONTAINER_ENGINE_PREFERENCE or $null
    #>
    $pref = ($env:CONTAINER_ENGINE_PREFERENCE) -as [string]
    # Use Test-Path Function: first to avoid triggering module/autoload discovery.
    if (Test-Path Function:docker -ErrorAction SilentlyContinue) { $hasDocker = $true } elseif (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) { $hasDocker = Test-CachedCommand docker } else { $hasDocker = $null -ne (Get-Command docker -ErrorAction SilentlyContinue) }
    if (Test-Path Function:'docker-compose' -ErrorAction SilentlyContinue) { $hasDockerComposeCmd = $true } elseif (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) { $hasDockerComposeCmd = Test-CachedCommand 'docker-compose' } else { $hasDockerComposeCmd = $null -ne (Get-Command 'docker-compose' -ErrorAction SilentlyContinue) }
    if (Test-Path Function:podman -ErrorAction SilentlyContinue) { $hasPodman = $true } elseif (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) { $hasPodman = Test-CachedCommand podman } else { $hasPodman = $null -ne (Get-Command podman -ErrorAction SilentlyContinue) }
    if (Test-Path Function:'podman-compose' -ErrorAction SilentlyContinue) { $hasPodmanComposeCmd = $true } elseif (Test-Path Function:Test-CachedCommand -ErrorAction SilentlyContinue) { $hasPodmanComposeCmd = Test-CachedCommand 'podman-compose' } else { $hasPodmanComposeCmd = $null -ne (Get-Command 'podman-compose' -ErrorAction SilentlyContinue) }

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

function Set-ContainerEnginePreference {
    param(
        [Parameter(Mandatory)][ValidateSet('docker', 'podman')] [string]$Engine
    )
    # Persist preference in environment for current session; users may set it in
    # their environment permanently via system/user env settings if desired.
    $env:CONTAINER_ENGINE_PREFERENCE = $Engine
    Write-Output "Container engine preference set to: $Engine"
}








