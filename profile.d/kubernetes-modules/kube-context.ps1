# ===============================================
# kube-context.ps1
# Kubernetes context and namespace helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
<#
.SYNOPSIS
    Kubernetes context and namespace helpers
.DESCRIPTION
    Set-KubeContext and Set-KubeNamespace with kubectx/kubens fallbacks.
.NOTES
    Loaded by kubernetes-enhanced.ps1 or directly.
#>
try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'kube-context') { return }
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
            Invoke-MissingToolWarning -ToolName 'kubectl'
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
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "kubernetes.context.switch" -Context @{
                    context = $Context
                }
            }
            else {
                Write-Error "Failed to run context command: $_"
            }
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
            Invoke-MissingToolWarning -ToolName 'kubectl'
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
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "kubernetes.namespace.switch" -Context @{
                    namespace = $Namespace
                }
            }
            else {
                Write-Error "Failed to run namespace command: $_"
            }
        }
    }
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'kube-context'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'kube-context' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load kube-context: "
    }
}
