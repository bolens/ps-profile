# ===============================================
# kube-logs.ps1
# Kubernetes log tailing
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
<#
.SYNOPSIS
    Kubernetes log tailing
.DESCRIPTION
    Tail-KubeLogs using stern or kubectl.
.NOTES
    Loaded by kubernetes-enhanced.ps1 or directly.
#>
try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'kube-logs') { return }
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
            Invoke-MissingToolWarning -ToolName 'kubectl'
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
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "kubernetes.logs.tail" -Context @{
                    resource  = $Resource
                    namespace = $Namespace
                    follow    = $Follow.IsPresent
                }
            }
            else {
                Write-Error "Failed to tail logs: $_"
            }
        }
    }
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'kube-logs'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'kube-logs' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load kube-logs: "
    }
}
