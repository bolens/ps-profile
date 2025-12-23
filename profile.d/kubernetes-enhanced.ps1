# ===============================================
# kubernetes-enhanced.ps1
# Enhanced Kubernetes tools and orchestration
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, kubectl, helm
# Environment: cloud, containers, development

<#
.SYNOPSIS
    Enhanced Kubernetes tools and orchestration fragment.

.DESCRIPTION
    Provides enhanced wrapper functions for Kubernetes management and orchestration tools:
    - kubectx/kubens: Context and namespace switching
    - k9s: Kubernetes TUI
    - stern: Log tailing
    - kubeseal: Sealed Secrets
    - minikube: Local Kubernetes cluster
    - kind: Kubernetes in Docker

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module enhances existing kubectl.ps1 and kube.ps1 modules.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'kubernetes-enhanced') { return }
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
    # Set-KubeContext - Switch Kubernetes context
    # ===============================================

    <#
    .SYNOPSIS
        Switches the active Kubernetes context.
    
    .DESCRIPTION
        Changes the active Kubernetes context using kubectx (if available) or kubectl.
        Lists available contexts if no context is specified.
    
    .PARAMETER ContextName
        Name of the context to switch to. If not specified, lists available contexts.
    
    .PARAMETER List
        List all available contexts instead of switching.
    
    .EXAMPLE
        Set-KubeContext -List
        
        Lists all available Kubernetes contexts.
    
    .EXAMPLE
        Set-KubeContext -ContextName "my-context"
        
        Switches to the specified context.
    
    .OUTPUTS
        System.String. Context information or list of contexts.
    #>
    function Set-KubeContext {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$ContextName,
            
            [switch]$List
        )

        # Prefer kubectx if available, fallback to kubectl
        $useKubectx = Test-CachedCommand 'kubectx'
        $useKubectl = Test-CachedCommand 'kubectl'

        if (-not $useKubectx -and -not $useKubectl) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'kubectl' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'kubectl' -InstallHint $installHint
            }
            else {
                Write-Warning "kubectl is not installed. Install it with: scoop install kubectl"
            }
            return
        }

        try {
            if ($List -or -not $ContextName) {
                if ($useKubectx) {
                    $output = & kubectx 2>&1
                }
                else {
                    $output = & kubectl config get-contexts -o name 2>&1
                }
                
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                else {
                    Write-Error "Failed to list contexts. Exit code: $LASTEXITCODE"
                }
            }
            else {
                if ($useKubectx) {
                    $output = & kubectx $ContextName 2>&1
                }
                else {
                    $output = & kubectl config use-context $ContextName 2>&1
                }
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Switched to context: $ContextName" -ForegroundColor Green
                    return $output
                }
                else {
                    Write-Error "Failed to switch context. Exit code: $LASTEXITCODE"
                }
            }
        }
        catch {
            Write-Error "Failed to run context command: $_"
        }
    }

    # ===============================================
    # Set-KubeNamespace - Switch namespace
    # ===============================================

    <#
    .SYNOPSIS
        Switches the active Kubernetes namespace.
    
    .DESCRIPTION
        Changes the active namespace using kubens (if available) or kubectl.
        Lists available namespaces if no namespace is specified.
    
    .PARAMETER Namespace
        Name of the namespace to switch to. If not specified, lists available namespaces.
    
    .PARAMETER List
        List all available namespaces instead of switching.
    
    .EXAMPLE
        Set-KubeNamespace -List
        
        Lists all available Kubernetes namespaces.
    
    .EXAMPLE
        Set-KubeNamespace -Namespace "production"
        
        Switches to the specified namespace.
    
    .OUTPUTS
        System.String. Namespace information or list of namespaces.
    #>
    function Set-KubeNamespace {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$Namespace,
            
            [switch]$List
        )

        # Prefer kubens if available, fallback to kubectl
        $useKubens = Test-CachedCommand 'kubens'
        $useKubectl = Test-CachedCommand 'kubectl'

        if (-not $useKubens -and -not $useKubectl) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'kubectl' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'kubectl' -InstallHint $installHint
            }
            else {
                Write-Warning "kubectl is not installed. Install it with: scoop install kubectl"
            }
            return
        }

        try {
            if ($List -or -not $Namespace) {
                if ($useKubens) {
                    $output = & kubens 2>&1
                }
                else {
                    $output = & kubectl get namespaces -o name 2>&1
                }
                
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                else {
                    Write-Error "Failed to list namespaces. Exit code: $LASTEXITCODE"
                }
            }
            else {
                if ($useKubens) {
                    $output = & kubens $Namespace 2>&1
                }
                else {
                    $output = & kubectl config set-context --current --namespace=$Namespace 2>&1
                }
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "Switched to namespace: $Namespace" -ForegroundColor Green
                    return $output
                }
                else {
                    Write-Error "Failed to switch namespace. Exit code: $LASTEXITCODE"
                }
            }
        }
        catch {
            Write-Error "Failed to run namespace command: $_"
        }
    }

    # ===============================================
    # Tail-KubeLogs - Tail pod logs
    # ===============================================

    <#
    .SYNOPSIS
        Tails logs from Kubernetes pods.
    
    .DESCRIPTION
        Uses stern (if available) or kubectl to tail logs from multiple pods
        matching a pattern. Stern provides better multi-pod log aggregation.
    
    .PARAMETER Pattern
        Pod name pattern to match (supports regex with stern).
    
    .PARAMETER Namespace
        Kubernetes namespace. Defaults to current namespace.
    
    .PARAMETER Container
        Optional container name to filter logs.
    
    .PARAMETER Follow
        Follow log output (like tail -f). Defaults to true.
    
    .EXAMPLE
        Tail-KubeLogs -Pattern "my-app"
        
        Tails logs from all pods matching "my-app".
    
    .EXAMPLE
        Tail-KubeLogs -Pattern "nginx" -Namespace "production" -Container "web"
        
        Tails logs from nginx pods in production namespace, container web.
    
    .OUTPUTS
        System.String. Log output stream.
    #>
    function Tail-KubeLogs {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Pattern,
            
            [string]$Namespace,
            
            [string]$Container,
            
            [switch]$Follow = $true
        )

        $useStern = Test-CachedCommand 'stern'
        $useKubectl = Test-CachedCommand 'kubectl'

        if (-not $useStern -and -not $useKubectl) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'kubectl' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'kubectl' -InstallHint $installHint
            }
            else {
                Write-Warning "kubectl is not installed. Install it with: scoop install kubectl"
            }
            return
        }

        try {
            if ($useStern) {
                $arguments = @($Pattern)
                
                if ($Namespace) {
                    $arguments += '-n', $Namespace
                }
                
                if ($Container) {
                    $arguments += '-c', $Container
                }
                
                if ($Follow) {
                    $arguments += '--tail', '0'
                }
                
                & stern $arguments
            }
            else {
                # Fallback to kubectl logs
                $arguments = @('logs', '-f', '-l', "app=$Pattern")
                
                if ($Namespace) {
                    $arguments += '-n', $Namespace
                }
                
                if ($Container) {
                    $arguments += '-c', $Container
                }
                
                & kubectl $arguments
            }
        }
        catch {
            Write-Error "Failed to tail logs: $_"
        }
    }

    # ===============================================
    # Get-KubeResources - Get resource information
    # ===============================================

    <#
    .SYNOPSIS
        Gets Kubernetes resource information.
    
    .DESCRIPTION
        Retrieves detailed information about Kubernetes resources using kubectl.
        Supports different output formats and resource types.
    
    .PARAMETER ResourceType
        Kubernetes resource type (e.g., pods, services, deployments).
    
    .PARAMETER ResourceName
        Optional specific resource name.
    
    .PARAMETER Namespace
        Kubernetes namespace. Defaults to current namespace.
    
    .PARAMETER OutputFormat
        Output format: wide, yaml, json. Defaults to wide.
    
    .EXAMPLE
        Get-KubeResources -ResourceType "pods"
        
        Lists all pods in the current namespace.
    
    .EXAMPLE
        Get-KubeResources -ResourceType "deployments" -Namespace "production" -OutputFormat "yaml"
        
        Gets deployments in production namespace as YAML.
    
    .OUTPUTS
        System.String. Resource information in the specified format.
    #>
    function Get-KubeResources {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ResourceType,
            
            [string]$ResourceName,
            
            [string]$Namespace,
            
            [ValidateSet('wide', 'yaml', 'json')]
            [string]$OutputFormat = 'wide'
        )

        if (-not (Test-CachedCommand 'kubectl')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'kubectl' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'kubectl' -InstallHint $installHint
            }
            else {
                Write-Warning "kubectl is not installed. Install it with: scoop install kubectl"
            }
            return
        }

        $arguments = @('get', $ResourceType)
        
        if ($ResourceName) {
            $arguments += $ResourceName
        }
        
        if ($Namespace) {
            $arguments += '-n', $Namespace
        }
        
        if ($OutputFormat -eq 'yaml') {
            $arguments += '-o', 'yaml'
        }
        elseif ($OutputFormat -eq 'json') {
            $arguments += '-o', 'json'
        }
        else {
            $arguments += '-o', 'wide'
        }

        try {
            $output = & kubectl $arguments 2>&1
            if ($LASTEXITCODE -eq 0) {
                return $output
            }
            else {
                Write-Error "Failed to get resources. Exit code: $LASTEXITCODE"
            }
        }
        catch {
            Write-Error "Failed to run kubectl: $_"
        }
    }

    # ===============================================
    # Start-Minikube - Start Minikube cluster
    # ===============================================

    <#
    .SYNOPSIS
        Starts a Minikube Kubernetes cluster.
    
    .DESCRIPTION
        Starts a local Minikube Kubernetes cluster with optional configuration.
        Supports different drivers and profile management.
    
    .PARAMETER Profile
        Minikube profile name. Defaults to minikube.
    
    .PARAMETER Driver
        Minikube driver: docker, hyperv, virtualbox, etc.
    
    .PARAMETER Status
        Check Minikube status instead of starting.
    
    .EXAMPLE
        Start-Minikube
        
        Starts Minikube cluster with default settings.
    
    .EXAMPLE
        Start-Minikube -Profile "dev" -Driver "docker"
        
        Starts Minikube cluster with custom profile and driver.
    
    .OUTPUTS
        System.String. Minikube status or startup output.
    #>
    function Start-Minikube {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$Profile = 'minikube',
            
            [string]$Driver,
            
            [switch]$Status
        )

        if (-not (Test-CachedCommand 'minikube')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'minikube' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'minikube' -InstallHint $installHint
            }
            else {
                Write-Warning "minikube is not installed. Install it with: scoop install minikube"
            }
            return
        }

        try {
            if ($Status) {
                $output = & minikube status -p $Profile 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                else {
                    Write-Error "Failed to get Minikube status. Exit code: $LASTEXITCODE"
                }
            }
            else {
                $arguments = @('start', '-p', $Profile)
                
                if ($Driver) {
                    $arguments += '--driver', $Driver
                }
                
                $output = & minikube $arguments 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                else {
                    Write-Error "Failed to start Minikube. Exit code: $LASTEXITCODE"
                }
            }
        }
        catch {
            Write-Error "Failed to run minikube: $_"
        }
    }

    # ===============================================
    # Start-K9s - Launch k9s TUI
    # ===============================================

    <#
    .SYNOPSIS
        Launches k9s Kubernetes TUI.
    
    .DESCRIPTION
        Starts k9s, a terminal UI for managing Kubernetes clusters.
        Provides an interactive interface for viewing and managing resources.
    
    .PARAMETER Namespace
        Optional namespace to open k9s in.
    
    .EXAMPLE
        Start-K9s
        
        Launches k9s with default settings.
    
    .EXAMPLE
        Start-K9s -Namespace "production"
        
        Launches k9s in the production namespace.
    #>
    function Start-K9s {
        [CmdletBinding()]
        param(
            [string]$Namespace
        )

        if (-not (Test-CachedCommand 'k9s')) {
            $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
            }
            else {
                Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'k9s' -RepoRoot $repoRoot
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'k9s' -InstallHint $installHint
            }
            else {
                Write-Warning "k9s is not installed. Install it with: scoop install k9s"
            }
            return
        }

        $arguments = @()
        
        if ($Namespace) {
            $arguments += '-n', $Namespace
        }

        try {
            & k9s $arguments
        }
        catch {
            Write-Error "Failed to launch k9s: $_"
        }
    }

    # Register functions and aliases
    if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
        Set-AgentModeFunction -Name 'Set-KubeContext' -Body ${function:Set-KubeContext}
        Set-AgentModeFunction -Name 'Set-KubeNamespace' -Body ${function:Set-KubeNamespace}
        Set-AgentModeFunction -Name 'Tail-KubeLogs' -Body ${function:Tail-KubeLogs}
        Set-AgentModeFunction -Name 'Get-KubeResources' -Body ${function:Get-KubeResources}
        Set-AgentModeFunction -Name 'Start-Minikube' -Body ${function:Start-Minikube}
        Set-AgentModeFunction -Name 'Start-K9s' -Body ${function:Start-K9s}
    }
    else {
        # Fallback: direct function registration
        Set-Item -Path Function:Set-KubeContext -Value ${function:Set-KubeContext} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Set-KubeNamespace -Value ${function:Set-KubeNamespace} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Tail-KubeLogs -Value ${function:Tail-KubeLogs} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Get-KubeResources -Value ${function:Get-KubeResources} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Start-Minikube -Value ${function:Start-Minikube} -Force -ErrorAction SilentlyContinue
        Set-Item -Path Function:Start-K9s -Value ${function:Start-K9s} -Force -ErrorAction SilentlyContinue
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'kubernetes-enhanced'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: kubernetes-enhanced" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load kubernetes-enhanced fragment: $($_.Exception.Message)"
    }
}
