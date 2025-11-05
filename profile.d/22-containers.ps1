# ===============================================
# 22-containers.ps1
# Container helpers consolidated (docker / podman / compose)
# These helpers are idempotent and prefer Docker if available, falling back
# to Podman. Each function checks for the available engine and compose
# implementation before calling.
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
if (-not (Test-Path Function:Start-ContainerCompose)) {
    <#
    .SYNOPSIS
        Starts container services using compose (Docker-first).
    .DESCRIPTION
        Runs 'compose up -d' using the available container engine, preferring Docker over Podman.
        Automatically detects and uses docker compose, docker-compose, podman compose, or podman-compose.
    #>
    function Start-ContainerCompose {
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
    Set-Alias -Name dcu -Value Start-ContainerCompose -ErrorAction SilentlyContinue
}

# docker-compose down
if (-not (Test-Path Function:Stop-ContainerCompose)) {
    <#
    .SYNOPSIS
        Stops container services using compose (Docker-first).
    .DESCRIPTION
        Runs 'compose down' using the available container engine, preferring Docker over Podman.
        Automatically detects and uses docker compose, docker-compose, podman compose, or podman-compose.
    #>
    function Stop-ContainerCompose {
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
    Set-Alias -Name dcd -Value Stop-ContainerCompose -ErrorAction SilentlyContinue
}

# docker-compose logs -f
if (-not (Test-Path Function:Get-ContainerComposeLogs)) {
    <#
    .SYNOPSIS
        Shows container logs using compose (Docker-first).
    .DESCRIPTION
        Runs 'compose logs -f' using the available container engine, preferring Docker over Podman.
        Automatically detects and uses docker compose, docker-compose, podman compose, or podman-compose.
    #>
    function Get-ContainerComposeLogs {
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
    Set-Alias -Name dcl -Value Get-ContainerComposeLogs -ErrorAction SilentlyContinue
}

# prune system for whichever engine
if (-not (Test-Path Function:Clear-ContainerSystem)) {
    <#
    .SYNOPSIS
        Prunes unused container system resources (Docker-first).
    .DESCRIPTION
        Runs 'system prune -f' using the available container engine, preferring Docker over Podman.
        Removes unused containers, networks, images, and build cache.
    #>
    function Clear-ContainerSystem {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        if ($info.Engine -in @('docker', 'docker-compose')) { docker system prune -f @args }
        elseif ($info.Engine -in @('podman', 'podman-compose')) { podman system prune -f @args }
        else { Write-Warning 'neither docker nor podman found' }
    }
    Set-Alias -Name dprune -Value Clear-ContainerSystem -ErrorAction SilentlyContinue
}

# Podman-first compose helpers (separate functions for convenience)
if (-not (Test-Path Function:Start-ContainerComposePodman)) {
    <#
    .SYNOPSIS
        Starts container services using compose (Podman-first).
    .DESCRIPTION
        Runs 'compose up -d' using the available container engine, preferring Podman over Docker.
        Automatically detects and uses podman compose, podman-compose, docker compose, or docker-compose.
    #>
    function Start-ContainerComposePodman {
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
    Set-Alias -Name pcu -Value Start-ContainerComposePodman -ErrorAction SilentlyContinue
}

if (-not (Test-Path Function:Stop-ContainerComposePodman)) {
    <#
    .SYNOPSIS
        Stops container services using compose (Podman-first).
    .DESCRIPTION
        Runs 'compose down' using the available container engine, preferring Podman over Docker.
        Automatically detects and uses podman compose, podman-compose, docker compose, or docker-compose.
    #>
    function Stop-ContainerComposePodman {
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
    Set-Alias -Name pcd -Value Stop-ContainerComposePodman -ErrorAction SilentlyContinue
}

if (-not (Test-Path Function:Get-ContainerComposeLogsPodman)) {
    <#
    .SYNOPSIS
        Shows container logs using compose (Podman-first).
    .DESCRIPTION
        Runs 'compose logs -f' using the available container engine, preferring Podman over Docker.
        Automatically detects and uses podman compose, podman-compose, docker compose, or docker-compose.
    #>
    function Get-ContainerComposeLogsPodman {
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
    Set-Alias -Name pcl -Value Get-ContainerComposeLogsPodman -ErrorAction SilentlyContinue
}

if (-not (Test-Path Function:Clear-ContainerSystemPodman)) {
    <#
    .SYNOPSIS
        Prunes unused container system resources (Podman-first).
    .DESCRIPTION
        Runs 'system prune -f' using the available container engine, preferring Podman over Docker.
        Removes unused containers, networks, images, and build cache.
    #>
    function Clear-ContainerSystemPodman {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        if ($info.Engine -in @('podman', 'podman-compose')) { podman system prune -f @args }
        elseif ($info.Engine -in @('docker', 'docker-compose')) { docker system prune -f @args }
        else { Write-Warning 'neither podman nor docker found' }
    }
    Set-Alias -Name pprune -Value Clear-ContainerSystemPodman -ErrorAction SilentlyContinue
}
