# ===============================================
# 22-containers.ps1
# Container helpers consolidated (docker / podman / compose)
# These helpers are idempotent and prefer Docker if available, falling back
# to Podman. Each function checks for the available engine and compose
# implementation before calling.
# ===============================================

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
    # Use Test-Path against the Function: provider for cheap existence checks where possible.
    # Fall back to Get-Command only when necessary (e.g., to detect compose subcommand support).
    $hasDocker = Test-Path Function:docker -or (Get-Command docker -ErrorAction SilentlyContinue) -NE $null
    $hasDockerComposeCmd = Test-Path Function:'docker-compose' -or (Get-Command docker-compose -ErrorAction SilentlyContinue) -NE $null
    $hasPodman = Test-Path Function:podman -or (Get-Command podman -ErrorAction SilentlyContinue) -NE $null
    $hasPodmanComposeCmd = Test-Path Function:'podman-compose' -or (Get-Command podman-compose -ErrorAction SilentlyContinue) -NE $null
    $info.HasDockerComposeCmd = $hasDockerComposeCmd
    $info.HasPodmanComposeCmd = $hasPodmanComposeCmd
    # Test compose subcommand support once (only when docker/podman present)
    if ($hasDocker) {
        try { & docker compose version *> $null; if ($LASTEXITCODE -eq 0) { $info.SupportsComposeSubcommand = $true } } catch {}
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

# docker-compose / docker compose up
if (-not (Test-Path Function:dcu)) {
    function dcu {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        switch ($info.Engine) {
            'docker' { docker compose up -D @args; return }
            'docker-compose' { docker-compose up -D @args; return }
            'podman' { podman compose up -D @args; return }
            'podman-compose' { podman-compose up -D @args; return }
            default { Write-Warning 'neither docker nor podman found' }
        }
    }
}

# docker-compose down
if (-not (Test-Path Function:dcd)) {
    function dcd {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        switch ($info.Engine) {
            'docker' { docker compose down @args; return }
            'docker-compose' { docker-compose down @args; return }
            'podman' { podman compose down @args; return }
            'podman-compose' { podman-compose down @args; return }
            default { Write-Warning 'neither docker nor podman found' }
        }
    }
}

# docker-compose logs -f
if (-not (Test-Path Function:dcl)) {
    function dcl {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        switch ($info.Engine) {
            'docker' { docker compose logs -f @args; return }
            'docker-compose' { docker-compose logs -f @args; return }
            'podman' { podman compose logs -f @args; return }
            'podman-compose' { podman-compose logs -f @args; return }
            default { Write-Warning 'neither docker nor podman found' }
        }
    }
}

# prune system for whichever engine
# prune system for whichever engine
if (-not (Test-Path Function:dprune)) {
    function dprune {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        if ($info.Engine -in @('docker', 'docker-compose')) { docker system prune -f @args }
        elseif ($info.Engine -in @('podman', 'podman-compose')) { podman system prune -f @args }
        else { Write-Warning 'neither docker nor podman found' }
    }
}

# Podman-first compose helpers (separate functions for convenience)
if (-not (Test-Path Function:pcu)) {
    function pcu {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        switch ($info.Engine) {
            'podman' { podman compose up -D @args }
            'podman-compose' { podman-compose up -D @args }
            'docker' { docker compose up -D @args }
            'docker-compose' { docker-compose up -D @args }
            default { Write-Warning 'neither podman nor docker found' }
        }
    }
}

if (-not (Test-Path Function:pcd)) {
    function pcd {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        switch ($info.Engine) {
            'podman' { podman compose down @args }
            'podman-compose' { podman-compose down @args }
            'docker' { docker compose down @args }
            'docker-compose' { docker-compose down @args }
            default { Write-Warning 'neither podman nor docker found' }
        }
    }
}

if (-not (Test-Path Function:pcl)) {
    function pcl {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        switch ($info.Engine) {
            'podman' { podman compose logs -f @args }
            'podman-compose' { podman-compose logs -f @args }
            'docker' { docker compose logs -f @args }
            'docker-compose' { docker-compose logs -f @args }
            default { Write-Warning 'neither podman nor docker found' }
        }
    }
}

if (-not (Test-Path Function:pprune)) {
    function pprune {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        if ($info.Engine -in @('podman', 'podman-compose')) { podman system prune -f @args }
        elseif ($info.Engine -in @('docker', 'docker-compose')) { docker system prune -f @args }
        else { Write-Warning 'neither podman nor docker found' }
    }
}












