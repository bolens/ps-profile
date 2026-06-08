# ===============================================
# Container compose functions (Podman-first)
# Podman Compose operations preferring Podman over Docker
# ===============================================

# Podman-first compose helpers (separate functions for convenience)
if (-not (Test-Path Function:Start-ContainerComposePodman)) {
    <#
    .SYNOPSIS
        Starts container services using compose (Podman-first).
    .DESCRIPTION
        Runs 'compose up -d' using the available container engine, preferring Podman over Docker.
        Automatically detects and uses podman compose, podman-compose, docker compose, or docker-compose.
    .PARAMETER args
        Additional arguments forwarded to compose up -d.
    .EXAMPLE
        Start-ContainerComposePodman
    #>
    function Start-ContainerComposePodman {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        switch ($info.Engine) {
            'podman' { podman compose up -d @args }
            'podman-compose' { podman-compose up -d @args }
            'docker' { docker compose up -d @args }
            'docker-compose' { docker-compose up -d @args }
            default { 
                $engineInfo = Get-ContainerEnginePreference
                if ($engineInfo.InstallationCommand) {
                    Write-Warning "Neither podman nor docker found. Install with: $($engineInfo.InstallationCommand)"
                }
                else {
                    Write-Warning 'neither podman nor docker found'
                }
            }
        }
    }
    Set-AgentModeAlias -Name 'pcu' -Target 'Start-ContainerComposePodman'
}

if (-not (Test-Path Function:Stop-ContainerComposePodman)) {
    <#
    .SYNOPSIS
        Stops container services using compose (Podman-first).
    .DESCRIPTION
        Runs 'compose down' using the available container engine, preferring Podman over Docker.
        Automatically detects and uses podman compose, podman-compose, docker compose, or docker-compose.
    .PARAMETER args
        Additional arguments forwarded to compose down.
    .EXAMPLE
        Stop-ContainerComposePodman
    #>
    function Stop-ContainerComposePodman {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        switch ($info.Engine) {
            'podman' { podman compose down @args }
            'podman-compose' { podman-compose down @args }
            'docker' { docker compose down @args }
            'docker-compose' { docker-compose down @args }
            default { 
                $engineInfo = Get-ContainerEnginePreference
                if ($engineInfo.InstallationCommand) {
                    Write-Warning "Neither podman nor docker found. Install with: $($engineInfo.InstallationCommand)"
                }
                else {
                    Write-Warning 'neither podman nor docker found'
                }
            }
        }
    }
    Set-AgentModeAlias -Name 'pcd' -Target 'Stop-ContainerComposePodman'
}

if (-not (Test-Path Function:Get-ContainerComposeLogsPodman)) {
    <#
    .SYNOPSIS
        Shows container logs using compose (Podman-first).
    .DESCRIPTION
        Runs 'compose logs -f' using the available container engine, preferring Podman over Docker.
        Automatically detects and uses podman compose, podman-compose, docker compose, or docker-compose.
    .PARAMETER args
        Additional arguments forwarded to compose logs -f.
    .EXAMPLE
        Get-ContainerComposeLogsPodman
    #>
    function Get-ContainerComposeLogsPodman {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        switch ($info.Engine) {
            'podman' { podman compose logs -f @args }
            'podman-compose' { podman-compose logs -f @args }
            'docker' { docker compose logs -f @args }
            'docker-compose' { docker-compose logs -f @args }
            default { 
                $engineInfo = Get-ContainerEnginePreference
                if ($engineInfo.InstallationCommand) {
                    Write-Warning "Neither podman nor docker found. Install with: $($engineInfo.InstallationCommand)"
                }
                else {
                    Write-Warning 'neither podman nor docker found'
                }
            }
        }
    }
    Set-AgentModeAlias -Name 'pcl' -Target 'Get-ContainerComposeLogsPodman'
}

if (-not (Test-Path Function:Clear-ContainerSystemPodman)) {
    <#
    .SYNOPSIS
        Prunes unused container system resources (Podman-first).
    .DESCRIPTION
        Runs 'system prune -f' using the available container engine, preferring Podman over Docker.
        Removes unused containers, networks, images, and build cache.
    .PARAMETER args
        Additional arguments forwarded to system prune -f.
    .EXAMPLE
        Clear-ContainerSystemPodman
    #>
    function Clear-ContainerSystemPodman {
        param([Parameter(ValueFromRemainingArguments = $true)] $args)
        $info = Get-ContainerEngineInfo
        if ($info.Engine -in @('podman', 'podman-compose')) { podman system prune -f @args }
        elseif ($info.Engine -in @('docker', 'docker-compose')) { docker system prune -f @args }
        else { 
            $engineInfo = Get-ContainerEnginePreference
            if ($engineInfo.InstallationCommand) {
                Write-Warning "Neither podman nor docker found. Install with: $($engineInfo.InstallationCommand)"
            }
            else {
                Write-Warning 'neither podman nor docker found'
            }
        }
    }
    Set-AgentModeAlias -Name 'pprune' -Target 'Clear-ContainerSystemPodman'
}

