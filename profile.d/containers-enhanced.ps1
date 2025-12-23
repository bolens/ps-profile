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
            Write-Error "Failed to launch podman-desktop: $_"
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
            Write-Error "Failed to launch rancher-desktop: $_"
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
            Write-Error "Failed to run kompose: $_"
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
            Write-Error "Failed to run Balena command: $_"
        }
    }

    # Register functions and aliases
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Start-PodmanDesktop' -Body ${function:Start-PodmanDesktop}
        Set-AgentModeFunction -Name 'Start-RancherDesktop' -Body ${function:Start-RancherDesktop}
        Set-AgentModeFunction -Name 'Convert-ComposeToK8s' -Body ${function:Convert-ComposeToK8s}
        Set-AgentModeFunction -Name 'Deploy-Balena' -Body ${function:Deploy-Balena}
    }
    else {
        # Fallback: direct function registration
        Set-Item -Path Function:Start-PodmanDesktop -Value ${function:Start-PodmanDesktop} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Start-RancherDesktop -Value ${function:Start-RancherDesktop} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Convert-ComposeToK8s -Value ${function:Convert-ComposeToK8s} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Deploy-Balena -Value ${function:Deploy-Balena} -Force -ErrorAction SilentlyContinue
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
