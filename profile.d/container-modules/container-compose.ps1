# ===============================================
# Container compose functions (Docker-first)
# Docker Compose operations preferring Docker over Podman
# ===============================================

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
            default { 
                $engineInfo = Get-ContainerEnginePreference
                if ($engineInfo.InstallationCommand) {
                    Write-Warning "Neither docker nor podman found. Install with: $($engineInfo.InstallationCommand)"
                }
                else {
                    Write-Warning 'neither docker nor podman found'
                }
            }
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
            default { 
                $engineInfo = Get-ContainerEnginePreference
                if ($engineInfo.InstallationCommand) {
                    Write-Warning "Neither docker nor podman found. Install with: $($engineInfo.InstallationCommand)"
                }
                else {
                    Write-Warning 'neither docker nor podman found'
                }
            }
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
            default { 
                $engineInfo = Get-ContainerEnginePreference
                if ($engineInfo.InstallationCommand) {
                    Write-Warning "Neither docker nor podman found. Install with: $($engineInfo.InstallationCommand)"
                }
                else {
                    Write-Warning 'neither docker nor podman found'
                }
            }
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
        else { 
            $engineInfo = Get-ContainerEnginePreference
            if ($engineInfo.InstallationCommand) {
                Write-Warning "Neither docker nor podman found. Install with: $($engineInfo.InstallationCommand)"
            }
            else {
                Write-Warning 'neither docker nor podman found'
            }
        }
    }
    Set-Alias -Name dprune -Value Clear-ContainerSystem -ErrorAction SilentlyContinue
}

