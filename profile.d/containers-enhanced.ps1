# ===============================================
# containers-enhanced.ps1
# Enhanced container tools and orchestration
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, containers
# Environment: containers, development

<#
.SYNOPSIS
    Enhanced container tools and orchestration fragment.

.DESCRIPTION
    Provides enhanced wrapper functions for container management and orchestration tools:
    - Podman Desktop: GUI for Podman
    - Rancher Desktop: Container management GUI
    - Kompose: Convert Docker Compose to Kubernetes
    - Balena: IoT container deployment

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module enhances existing containers.ps1 module.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'containers-enhanced') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
        }
        else {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # Start-PodmanDesktop - Launch Podman Desktop
    # ===============================================

    <#
    .SYNOPSIS
        Launches Podman Desktop GUI.
    
    .DESCRIPTION
        Starts Podman Desktop, a graphical interface for managing Podman containers,
        images, and volumes.
    
    .EXAMPLE
        Start-PodmanDesktop
        
        Launches Podman Desktop GUI.
    #>
    function Start-PodmanDesktop {
        [CmdletBinding()]
        param()

        if (-not (Test-CachedCommand 'podman-desktop')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'podman-desktop' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'podman-desktop' -InstallHint $installHint
            }
            else {
                Write-Warning "podman-desktop is not installed. Install it with: scoop install podman-desktop"
            }
            return
        }

        try {
            Start-Process -FilePath 'podman-desktop' -ErrorAction Stop
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "containers.podman-desktop.launch" -Context @{}
            }
            else {
                Write-Error "Failed to launch podman-desktop: $_"
            }
        }
    }

    # ===============================================
    # Start-RancherDesktop - Launch Rancher Desktop
    # ===============================================

    <#
    .SYNOPSIS
        Launches Rancher Desktop GUI.
    
    .DESCRIPTION
        Starts Rancher Desktop, a container management platform with Kubernetes support.
        Provides a GUI for managing containers, images, and Kubernetes clusters.
    
    .EXAMPLE
        Start-RancherDesktop
        
        Launches Rancher Desktop GUI.
    #>
    function Start-RancherDesktop {
        [CmdletBinding()]
        param()

        if (-not (Test-CachedCommand 'rancher-desktop')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'rancher-desktop' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'rancher-desktop' -InstallHint $installHint
            }
            else {
                Write-Warning "rancher-desktop is not installed. Install it with: scoop install rancher-desktop"
            }
            return
        }

        try {
            Start-Process -FilePath 'rancher-desktop' -ErrorAction Stop
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "containers.rancher-desktop.launch" -Context @{}
            }
            else {
                Write-Error "Failed to launch rancher-desktop: $_"
            }
        }
    }

    # ===============================================
    # Convert-ComposeToK8s - Convert Compose to Kubernetes
    # ===============================================

    <#
    .SYNOPSIS
        Converts Docker Compose files to Kubernetes manifests.
    
    .DESCRIPTION
        Uses kompose to convert docker-compose.yml files to Kubernetes
        deployment and service manifests.
    
    .PARAMETER ComposeFile
        Path to the docker-compose.yml file. Defaults to docker-compose.yml in current directory.
    
    .PARAMETER OutputPath
        Directory where Kubernetes manifests will be saved. Defaults to current directory.
    
    .PARAMETER Format
        Output format: yaml, json. Defaults to yaml.
    
    .EXAMPLE
        Convert-ComposeToK8s
        
        Converts docker-compose.yml in current directory to Kubernetes manifests.
    
    .EXAMPLE
        Convert-ComposeToK8s -ComposeFile "docker-compose.prod.yml" -OutputPath "k8s/"
        
        Converts the specified compose file and saves manifests to k8s/ directory.
    
    .OUTPUTS
        System.String. Path to the output directory.
    #>
    function Convert-ComposeToK8s {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string])]
        param(
            [string]$ComposeFile = 'docker-compose.yml',
            
            [string]$OutputPath = (Get-Location).Path,
            
            [ValidateSet('yaml', 'json')]
            [string]$Format = 'yaml'
        )

        if (-not (Test-CachedCommand 'kompose')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'kompose' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'kompose' -InstallHint $installHint
            }
            else {
                Write-Warning "kompose is not installed. Install it with: scoop install kompose"
            }
            return
        }

        if (-not (Test-Path -LiteralPath $ComposeFile)) {
            Write-Error "Compose file not found: $ComposeFile"
            return
        }

        if (-not (Test-Path -LiteralPath $OutputPath)) {
            New-Item -ItemType Directory -Path $OutputPath -Force | Out-Null
        }

        if (-not $PSCmdlet.ShouldProcess($OutputPath, "Convert Compose to Kubernetes")) {
            return
        }

        $arguments = @('convert', '-f', $ComposeFile, '-o', $OutputPath)
        
        if ($Format -eq 'json') {
            $arguments += '--json'
        }

        try {
            & kompose $arguments 2>&1 | Out-Null
            if ($LASTEXITCODE -eq 0) {
                return $OutputPath
            }
            else {
                Write-Error "Kompose conversion failed. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "containers.kompose.convert" -Context @{
                    compose_file = $ComposeFile
                    output_path  = $OutputPath
                    format       = $Format
                }
            }
            else {
                Write-Error "Failed to run kompose: $_"
            }
        }
    }

    # ===============================================
    # Deploy-Balena - Balena deployment helpers
    # ===============================================

    <#
    .SYNOPSIS
        Deploys to Balena devices.
    
    .DESCRIPTION
        Provides helper functions for Balena IoT container deployments.
        Supports pushing applications to Balena devices.
    
    .PARAMETER Action
        Action to perform: push, logs, ssh, status. Defaults to push.
    
    .PARAMETER Application
        Balena application name.
    
    .PARAMETER Device
        Optional device UUID or name.
    
    .EXAMPLE
        Deploy-Balena -Application "my-app" -Action "push"
        
        Pushes the current directory to Balena application.
    
    .EXAMPLE
        Deploy-Balena -Application "my-app" -Action "logs" -Device "device-uuid"
        
        Shows logs from a specific device.
    
    .OUTPUTS
        System.String. Deployment status or command output.
    #>
    function Deploy-Balena {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [ValidateSet('push', 'logs', 'ssh', 'status')]
            [string]$Action = 'push',
            
            [string]$Application,
            
            [string]$Device
        )

        if (-not (Test-CachedCommand 'balena')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'balena-cli' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'balena' -InstallHint $installHint
            }
            else {
                Write-Warning "balena is not installed. Install it with: scoop install balena-cli"
            }
            return
        }

        try {
            switch ($Action) {
                'push' {
                    $arguments = @('push', $Application)
                    $output = & balena $arguments 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Balena push failed. Exit code: $LASTEXITCODE"
                    }
                }
                'logs' {
                    $arguments = @('logs', $Application)
                    if ($Device) {
                        $arguments += '--device', $Device
                    }
                    $output = & balena $arguments 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Failed to get Balena logs. Exit code: $LASTEXITCODE"
                    }
                }
                'ssh' {
                    if (-not $Device) {
                        Write-Error "Device parameter is required for SSH action"
                        return
                    }
                    $arguments = @('ssh', $Device)
                    $output = & balena $arguments 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Failed to SSH to Balena device. Exit code: $LASTEXITCODE"
                    }
                }
                'status' {
                    $arguments = @('status')
                    if ($Application) {
                        $arguments += '--application', $Application
                    }
                    $output = & balena $arguments 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Failed to get Balena status. Exit code: $LASTEXITCODE"
                    }
                }
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "containers.balena.deploy" -Context @{
                    action      = $Action
                    application = $Application
                    device      = $Device
                }
            }
            else {
                Write-Error "Failed to run Balena command: $_"
            }
        }
    }

    # ===============================================
    # Clean-Containers - Clean up containers/images
    # ===============================================

    <#
    .SYNOPSIS
        Cleans up containers, images, and volumes.
    
    .DESCRIPTION
        Removes stopped containers, unused images, and optionally volumes.
        Works with both Docker and Podman.
    
    .PARAMETER RemoveVolumes
        Also remove unused volumes.
    
    .PARAMETER RemoveAll
        Remove all containers and images, not just unused ones.
    
    .PARAMETER PruneSystem
        Prune the entire system (all unused resources).
    
    .EXAMPLE
        Clean-Containers
        
        Removes stopped containers and unused images.
    
    .EXAMPLE
        Clean-Containers -RemoveVolumes
        
        Also removes unused volumes.
    
    .EXAMPLE
        Clean-Containers -PruneSystem
        
        Prunes all unused system resources.
    
    .OUTPUTS
        System.String. Output from cleanup commands.
    #>
    function Clean-Containers {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string])]
        param(
            [switch]$RemoveVolumes,
            
            [switch]$RemoveAll,
            
            [switch]$PruneSystem
        )

        $engineInfo = if (Get-Command Get-ContainerEnginePreference -ErrorAction SilentlyContinue) {
            Get-ContainerEnginePreference
        }
        else {
            @{
                Engine    = if (Test-CachedCommand 'docker') { 'docker' } elseif (Test-CachedCommand 'podman') { 'podman' } else { $null }
                Available = (Test-CachedCommand 'docker') -or (Test-CachedCommand 'podman')
            }
        }

        if (-not $engineInfo.Available) {
            Write-MissingToolWarning -Tool 'docker/podman' -InstallHint 'Install with: scoop install docker or scoop install podman'
            return
        }

        $engine = $engineInfo.Engine
        if (-not $engine) {
            $engine = if ($engineInfo.DockerAvailable) { 'docker' } else { 'podman' }
        }

        try {
            if ($PruneSystem) {
                if (-not $PSCmdlet.ShouldProcess("system", "Prune all unused resources")) {
                    return
                }
                $output = & $engine system prune -a -f 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                else {
                    Write-Error "Failed to prune system. Exit code: $LASTEXITCODE"
                }
            }
            elseif ($RemoveAll) {
                if (-not $PSCmdlet.ShouldProcess("all containers and images", "Remove")) {
                    return
                }
                # Remove all containers
                $containerOutput = & $engine ps -aq 2>&1
                if ($LASTEXITCODE -eq 0 -and $containerOutput) {
                    & $engine rm -f $containerOutput.Split("`n") 2>&1 | Out-Null
                }
                # Remove all images
                $imageOutput = & $engine images -aq 2>&1
                if ($LASTEXITCODE -eq 0 -and $imageOutput) {
                    & $engine rmi -f $imageOutput.Split("`n") 2>&1 | Out-Null
                }
                return "Removed all containers and images"
            }
            else {
                if (-not $PSCmdlet.ShouldProcess("stopped containers and unused images", "Remove")) {
                    return
                }
                $args = @('container', 'prune', '-f')
                if ($RemoveVolumes) {
                    $args += '--volumes'
                }
                $output = & $engine $args 2>&1
                if ($LASTEXITCODE -eq 0) {
                    # Also prune images
                    & $engine image prune -a -f 2>&1 | Out-Null
                    return $output
                }
                else {
                    Write-Error "Failed to clean containers. Exit code: $LASTEXITCODE"
                }
            }
        }
        catch {
            Write-Error "Failed to clean containers: $_"
        }
    }

    # ===============================================
    # Export-ContainerLogs - Export container logs
    # ===============================================

    <#
    .SYNOPSIS
        Exports container logs to a file.
    
    .DESCRIPTION
        Saves container logs to a file. Works with both Docker and Podman.
    
    .PARAMETER Container
        Container name or ID. If not specified, exports logs for all containers.
    
    .PARAMETER OutputPath
        Path to save log file. Defaults to container-logs-{timestamp}.txt.
    
    .PARAMETER Tail
        Number of lines to show from the end of logs. Defaults to all.
    
    .PARAMETER Since
        Show logs since timestamp (e.g., "2023-01-01T00:00:00").
    
    .EXAMPLE
        Export-ContainerLogs -Container "my-container"
        
        Exports logs for my-container.
    
    .EXAMPLE
        Export-ContainerLogs -Container "my-container" -OutputPath "logs.txt" -Tail 100
        
        Exports last 100 lines to logs.txt.
    
    .OUTPUTS
        System.String. Path to the exported log file.
    #>
    function Export-ContainerLogs {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$Container,
            
            [string]$OutputPath,
            
            [int]$Tail = 0,
            
            [string]$Since
        )

        $engineInfo = if (Get-Command Get-ContainerEnginePreference -ErrorAction SilentlyContinue) {
            Get-ContainerEnginePreference
        }
        else {
            @{
                Engine    = if (Test-CachedCommand 'docker') { 'docker' } elseif (Test-CachedCommand 'podman') { 'podman' } else { $null }
                Available = (Test-CachedCommand 'docker') -or (Test-CachedCommand 'podman')
            }
        }

        if (-not $engineInfo.Available) {
            Write-MissingToolWarning -Tool 'docker/podman' -InstallHint 'Install with: scoop install docker or scoop install podman'
            return
        }

        $engine = $engineInfo.Engine
        if (-not $engine) {
            $engine = if ($engineInfo.DockerAvailable) { 'docker' } else { 'podman' }
        }

        if (-not $OutputPath) {
            $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
            $OutputPath = "container-logs-$timestamp.txt"
        }

        try {
            $containers = @()
            if ($Container) {
                $containers = @($Container)
            }
            else {
                $containerList = & $engine ps -aq 2>&1
                if ($LASTEXITCODE -eq 0 -and $containerList) {
                    $containers = $containerList.Split("`n") | Where-Object { $_.Trim() }
                }
            }

            if ($containers.Count -eq 0) {
                Write-Warning "No containers found"
                return $null
            }

            $logContent = @()
            foreach ($containerId in $containers) {
                $args = @('logs')
                if ($Tail -gt 0) {
                    $args += '--tail', $Tail.ToString()
                }
                if ($Since) {
                    $args += '--since', $Since
                }
                $args += $containerId

                $logOutput = & $engine $args 2>&1
                if ($LASTEXITCODE -eq 0) {
                    $logContent += "=== Container: $containerId ==="
                    $logContent += $logOutput
                    $logContent += ""
                }
            }

            $logContent | Out-File -FilePath $OutputPath -Encoding UTF8
            return $OutputPath
        }
        catch {
            Write-Error "Failed to export container logs: $_"
            return $null
        }
    }

    # ===============================================
    # Get-ContainerStats - Container statistics
    # ===============================================

    <#
    .SYNOPSIS
        Gets container resource usage statistics.
    
    .DESCRIPTION
        Displays real-time or one-time statistics for containers.
        Works with both Docker and Podman.
    
    .PARAMETER Container
        Container name or ID. If not specified, shows stats for all containers.
    
    .PARAMETER NoStream
        Disable streaming (show stats once and exit).
    
    .PARAMETER Format
        Output format: table, json. Defaults to table.
    
    .EXAMPLE
        Get-ContainerStats
        
        Shows real-time stats for all containers.
    
    .EXAMPLE
        Get-ContainerStats -Container "my-container" -NoStream
        
        Shows one-time stats for my-container.
    
    .OUTPUTS
        System.String. Container statistics output.
    #>
    function Get-ContainerStats {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$Container,
            
            [switch]$NoStream,
            
            [ValidateSet('table', 'json')]
            [string]$Format = 'table'
        )

        $engineInfo = if (Get-Command Get-ContainerEnginePreference -ErrorAction SilentlyContinue) {
            Get-ContainerEnginePreference
        }
        else {
            @{
                Engine    = if (Test-CachedCommand 'docker') { 'docker' } elseif (Test-CachedCommand 'podman') { 'podman' } else { $null }
                Available = (Test-CachedCommand 'docker') -or (Test-CachedCommand 'podman')
            }
        }

        if (-not $engineInfo.Available) {
            Write-MissingToolWarning -Tool 'docker/podman' -InstallHint 'Install with: scoop install docker or scoop install podman'
            return
        }

        $engine = $engineInfo.Engine
        if (-not $engine) {
            $engine = if ($engineInfo.DockerAvailable) { 'docker' } else { 'podman' }
        }

        try {
            $args = @('stats')
            if ($NoStream) {
                $args += '--no-stream'
            }
            if ($Format -eq 'json') {
                $args += '--format', 'json'
            }
            if ($Container) {
                $args += $Container
            }

            $output = & $engine $args 2>&1
            if ($LASTEXITCODE -eq 0) {
                return $output
            }
            else {
                Write-Error "Failed to get container stats. Exit code: $LASTEXITCODE"
                return ""
            }
        }
        catch {
            Write-Error "Failed to get container stats: $_"
            return ""
        }
    }

    # ===============================================
    # Backup-ContainerVolumes - Backup volumes
    # ===============================================

    <#
    .SYNOPSIS
        Backs up container volumes to a tar archive.
    
    .DESCRIPTION
        Creates a backup of container volumes. Works with both Docker and Podman.
    
    .PARAMETER Volume
        Volume name. If not specified, backs up all volumes.
    
    .PARAMETER OutputPath
        Path to save backup file. Defaults to volume-backup-{timestamp}.tar.gz.
    
    .PARAMETER Compress
        Compress the backup archive (gzip).
    
    .EXAMPLE
        Backup-ContainerVolumes -Volume "my-volume"
        
        Backs up my-volume to a tar file.
    
    .EXAMPLE
        Backup-ContainerVolumes -Compress
        
        Backs up all volumes to a compressed archive.
    
    .OUTPUTS
        System.String. Path to the backup file.
    #>
    function Backup-ContainerVolumes {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string])]
        param(
            [string]$Volume,
            
            [string]$OutputPath,
            
            [switch]$Compress
        )

        $engineInfo = if (Get-Command Get-ContainerEnginePreference -ErrorAction SilentlyContinue) {
            Get-ContainerEnginePreference
        }
        else {
            @{
                Engine    = if (Test-CachedCommand 'docker') { 'docker' } elseif (Test-CachedCommand 'podman') { 'podman' } else { $null }
                Available = (Test-CachedCommand 'docker') -or (Test-CachedCommand 'podman')
            }
        }

        if (-not $engineInfo.Available) {
            Write-MissingToolWarning -Tool 'docker/podman' -InstallHint 'Install with: scoop install docker or scoop install podman'
            return
        }

        $engine = $engineInfo.Engine
        if (-not $engine) {
            $engine = if ($engineInfo.DockerAvailable) { 'docker' } else { 'podman' }
        }

        if (-not $OutputPath) {
            $timestamp = Get-Date -Format 'yyyyMMddHHmmss'
            $extension = if ($Compress) { 'tar.gz' } else { 'tar' }
            $OutputPath = "volume-backup-$timestamp.$extension"
        }

        try {
            $volumes = @()
            if ($Volume) {
                $volumes = @($Volume)
            }
            else {
                $volumeList = & $engine volume ls -q 2>&1
                if ($LASTEXITCODE -eq 0 -and $volumeList) {
                    $volumes = $volumeList.Split("`n") | Where-Object { $_.Trim() }
                }
            }

            if ($volumes.Count -eq 0) {
                Write-Warning "No volumes found"
                return $null
            }

            if (-not $PSCmdlet.ShouldProcess($OutputPath, "Backup volumes")) {
                return
            }

            # Create temporary container to access volumes
            $tempContainer = "backup-temp-$(Get-Random)"
            $backupFiles = @()

            foreach ($vol in $volumes) {
                try {
                    # Create a temporary container with the volume mounted
                    $mountPath = "/backup"
                    & $engine run --rm -v "${vol}:${mountPath}" -v "$(Get-Location):/output" alpine tar czf "/output/${vol}-backup.tar.gz" -C $mountPath . 2>&1 | Out-Null
                    
                    if ($LASTEXITCODE -eq 0) {
                        $backupFiles += "${vol}-backup.tar.gz"
                    }
                }
                catch {
                    Write-Warning "Failed to backup volume $vol : $_"
                }
            }

            if ($backupFiles.Count -gt 0) {
                # Combine all backups into one archive if multiple volumes
                if ($backupFiles.Count -gt 1) {
                    $combinedBackup = $OutputPath
                    & $engine run --rm -v "$(Get-Location):/backup" alpine tar czf "/backup/$combinedBackup" -C /backup $backupFiles 2>&1 | Out-Null
                    # Remove individual backups
                    $backupFiles | ForEach-Object { Remove-Item $_ -ErrorAction SilentlyContinue }
                    return (Join-Path (Get-Location) $combinedBackup)
                }
                else {
                    # Rename single backup to output path
                    $singleBackup = $backupFiles[0]
                    if ($singleBackup -ne $OutputPath) {
                        Move-Item -Path $singleBackup -Destination $OutputPath -Force
                    }
                    return (Join-Path (Get-Location) $OutputPath)
                }
            }
            else {
                Write-Error "Failed to backup volumes"
                return $null
            }
        }
        catch {
            Write-Error "Failed to backup container volumes: $_"
            return $null
        }
    }

    # ===============================================
    # Restore-ContainerVolumes - Restore volumes
    # ===============================================

    <#
    .SYNOPSIS
        Restores container volumes from a backup archive.
    
    .DESCRIPTION
        Restores volumes from a backup tar archive. Works with both Docker and Podman.
    
    .PARAMETER BackupPath
        Path to the backup archive file.
    
    .PARAMETER Volume
        Volume name to restore to. If not specified, creates a new volume.
    
    .PARAMETER CreateVolume
        Create a new volume if it doesn't exist.
    
    .EXAMPLE
        Restore-ContainerVolumes -BackupPath "volume-backup.tar.gz"
        
        Restores volumes from backup archive.
    
    .EXAMPLE
        Restore-ContainerVolumes -BackupPath "backup.tar.gz" -Volume "my-volume" -CreateVolume
        
        Restores to my-volume, creating it if needed.
    
    .OUTPUTS
        System.String. Name of the restored volume.
    #>
    function Restore-ContainerVolumes {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$BackupPath,
            
            [string]$Volume,
            
            [switch]$CreateVolume
        )

        $engineInfo = if (Get-Command Get-ContainerEnginePreference -ErrorAction SilentlyContinue) {
            Get-ContainerEnginePreference
        }
        else {
            @{
                Engine    = if (Test-CachedCommand 'docker') { 'docker' } elseif (Test-CachedCommand 'podman') { 'podman' } else { $null }
                Available = (Test-CachedCommand 'docker') -or (Test-CachedCommand 'podman')
            }
        }

        if (-not $engineInfo.Available) {
            Write-MissingToolWarning -Tool 'docker/podman' -InstallHint 'Install with: scoop install docker or scoop install podman'
            return
        }

        $engine = $engineInfo.Engine
        if (-not $engine) {
            $engine = if ($engineInfo.DockerAvailable) { 'docker' } else { 'podman' }
        }

        if (-not (Test-Path -LiteralPath $BackupPath)) {
            Write-Error "Backup file not found: $BackupPath"
            return
        }

        try {
            $backupName = Split-Path -Leaf $BackupPath
            $backupDir = Split-Path -Parent $BackupPath
            if (-not $backupDir) {
                $backupDir = (Get-Location).Path
            }

            if (-not $Volume) {
                $Volume = "restored-volume-$(Get-Date -Format 'yyyyMMddHHmmss')"
            }

            if (-not $PSCmdlet.ShouldProcess($Volume, "Restore from backup")) {
                return
            }

            # Check if volume exists
            $volumeExists = & $engine volume inspect $Volume 2>&1
            if ($LASTEXITCODE -ne 0 -and $CreateVolume) {
                & $engine volume create $Volume 2>&1 | Out-Null
            }

            # Restore using temporary container
            $mountPath = "/restore"
            $backupMount = "/backup"
            & $engine run --rm -v "${Volume}:${mountPath}" -v "${backupDir}:${backupMount}" alpine sh -c "cd $mountPath && tar xzf ${backupMount}/${backupName}" 2>&1 | Out-Null

            if ($LASTEXITCODE -eq 0) {
                return $Volume
            }
            else {
                Write-Error "Failed to restore volume. Exit code: $LASTEXITCODE"
                return $null
            }
        }
        catch {
            Write-Error "Failed to restore container volumes: $_"
            return $null
        }
    }

    # ===============================================
    # Health-CheckContainers - Health check all containers
    # ===============================================

    <#
    .SYNOPSIS
        Performs health checks on all running containers.
    
    .DESCRIPTION
        Checks the health status of all running containers.
        Works with both Docker and Podman.
    
    .PARAMETER Container
        Container name or ID. If not specified, checks all containers.
    
    .PARAMETER Format
        Output format: table, json. Defaults to table.
    
    .EXAMPLE
        Health-CheckContainers
        
        Checks health of all running containers.
    
    .EXAMPLE
        Health-CheckContainers -Container "my-container" -Format json
        
        Checks health of my-container in JSON format.
    
    .OUTPUTS
        System.Object. Health check results.
    #>
    function Health-CheckContainers {
        [CmdletBinding()]
        [OutputType([object])]
        param(
            [string]$Container,
            
            [ValidateSet('table', 'json')]
            [string]$Format = 'table'
        )

        $engineInfo = if (Get-Command Get-ContainerEnginePreference -ErrorAction SilentlyContinue) {
            Get-ContainerEnginePreference
        }
        else {
            @{
                Engine    = if (Test-CachedCommand 'docker') { 'docker' } elseif (Test-CachedCommand 'podman') { 'podman' } else { $null }
                Available = (Test-CachedCommand 'docker') -or (Test-CachedCommand 'podman')
            }
        }

        if (-not $engineInfo.Available) {
            Write-MissingToolWarning -Tool 'docker/podman' -InstallHint 'Install with: scoop install docker or scoop install podman'
            return
        }

        $engine = $engineInfo.Engine
        if (-not $engine) {
            $engine = if ($engineInfo.DockerAvailable) { 'docker' } else { 'podman' }
        }

        try {
            $containers = @()
            if ($Container) {
                $containers = @($Container)
            }
            else {
                $containerList = & $engine ps --format "{{.ID}}" 2>&1
                if ($LASTEXITCODE -eq 0 -and $containerList) {
                    $containers = $containerList.Split("`n") | Where-Object { $_.Trim() }
                }
            }

            if ($containers.Count -eq 0) {
                Write-Warning "No running containers found"
                return @()
            }

            $results = @()
            foreach ($containerId in $containers) {
                $inspectOutput = & $engine inspect $containerId --format '{{json .State.Health}}' 2>&1
                if ($LASTEXITCODE -eq 0 -and $inspectOutput) {
                    try {
                        $health = $inspectOutput | ConvertFrom-Json
                        $results += [PSCustomObject]@{
                            Container     = $containerId
                            Status        = $health.Status
                            FailingStreak = $health.FailingStreak
                            Logs          = $health.Log
                        }
                    }
                    catch {
                        # Container may not have health check configured
                        $results += [PSCustomObject]@{
                            Container     = $containerId
                            Status        = "no-healthcheck"
                            FailingStreak = 0
                            Logs          = @()
                        }
                    }
                }
                else {
                    # Fallback: check if container is running
                    $state = & $engine inspect $containerId --format '{{.State.Status}}' 2>&1
                    $results += [PSCustomObject]@{
                        Container     = $containerId
                        Status        = if ($state -eq 'running') { 'running' } else { $state }
                        FailingStreak = 0
                        Logs          = @()
                    }
                }
            }

            if ($Format -eq 'json') {
                return $results | ConvertTo-Json -Depth 10
            }
            else {
                return $results
            }
        }
        catch {
            Write-Error "Failed to check container health: $_"
            return @()
        }
    }

    # Register functions and aliases
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Start-PodmanDesktop' -Body ${function:Start-PodmanDesktop}
        Set-AgentModeFunction -Name 'Start-RancherDesktop' -Body ${function:Start-RancherDesktop}
        Set-AgentModeFunction -Name 'Convert-ComposeToK8s' -Body ${function:Convert-ComposeToK8s}
        Set-AgentModeFunction -Name 'Deploy-Balena' -Body ${function:Deploy-Balena}
        Set-AgentModeFunction -Name 'Clean-Containers' -Body ${function:Clean-Containers}
        Set-AgentModeFunction -Name 'Export-ContainerLogs' -Body ${function:Export-ContainerLogs}
        Set-AgentModeFunction -Name 'Get-ContainerStats' -Body ${function:Get-ContainerStats}
        Set-AgentModeFunction -Name 'Backup-ContainerVolumes' -Body ${function:Backup-ContainerVolumes}
        Set-AgentModeFunction -Name 'Restore-ContainerVolumes' -Body ${function:Restore-ContainerVolumes}
        Set-AgentModeFunction -Name 'Health-CheckContainers' -Body ${function:Health-CheckContainers}
    }
    else {
        # Fallback: direct function registration
        Set-Item -Path Function:Start-PodmanDesktop -Value ${function:Start-PodmanDesktop} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Start-RancherDesktop -Value ${function:Start-RancherDesktop} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Convert-ComposeToK8s -Value ${function:Convert-ComposeToK8s} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Deploy-Balena -Value ${function:Deploy-Balena} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Clean-Containers -Value ${function:Clean-Containers} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Export-ContainerLogs -Value ${function:Export-ContainerLogs} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-ContainerStats -Value ${function:Get-ContainerStats} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Backup-ContainerVolumes -Value ${function:Backup-ContainerVolumes} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Restore-ContainerVolumes -Value ${function:Restore-ContainerVolumes} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Health-CheckContainers -Value ${function:Health-CheckContainers} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'containers-enhanced'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: containers-enhanced" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load containers-enhanced fragment: $($_.Exception.Message)"
    }
}
