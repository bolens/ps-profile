# ===============================================
# kube-console.ps1
# Kubernetes console tools
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, kube-context
<#
.SYNOPSIS
    Kubernetes console tools
.DESCRIPTION
    Start-Minikube and Start-K9s helpers.
.NOTES
    Loaded by kubernetes-enhanced.ps1 or directly.
#>
try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'kube-console') { return }
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
    

    .OUTPUTS
        System.String. Minikube status or startup output.

    .EXAMPLE
    Start-Minikube -Profile 'value' -Driver 'value'
        Starts Minikube cluster with default settings.
    

    .EXAMPLE
        Start-Minikube -Profile "dev" -Driver "docker"
        
        Starts Minikube cluster with custom profile and driver.
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
            Invoke-MissingToolWarning -ToolName 'minikube'
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
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "kubernetes.minikube.start" -Context @{
                    profile      = $Profile
                    driver       = $Driver
                    status_check = $Status.IsPresent
                }
            }
            else {
                Write-Error "Failed to run minikube: $_"
            }
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
    Start-K9s -Namespace 'value'
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
            Invoke-MissingToolWarning -ToolName 'k9s'
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
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'kube-console'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'kube-console' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load kube-console: "
    }
}
