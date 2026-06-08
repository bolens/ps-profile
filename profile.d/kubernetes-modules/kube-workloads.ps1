# ===============================================
# kube-workloads.ps1
# Kubernetes workload operations
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
<#
.SYNOPSIS
    Kubernetes workload operations
.DESCRIPTION
    Resource get/describe/apply, exec, and port-forward helpers.
.NOTES
    Loaded by kubernetes-enhanced.ps1 or directly.
#>
try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'kube-workloads') { return }
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
    

    .OUTPUTS
        System.String. Resource information in the specified format.

    .EXAMPLE
        Get-KubeResources -ResourceType "pods"
        
        Lists all pods in the current namespace.
    

    .EXAMPLE
        Get-KubeResources -ResourceType "deployments" -Namespace "production" -OutputFormat "yaml"
        
        Gets deployments in production namespace as YAML.
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
            Invoke-MissingToolWarning -ToolName 'kubectl'
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
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "kubernetes.resources.get" -Context @{
                    resource_type = $ResourceType
                    resource_name = $ResourceName
                    namespace     = $Namespace
                    output_format = $OutputFormat
                }
            }
            else {
                Write-Error "Failed to run kubectl: $_"
            }
        }
    }

    # ===============================================
    # Exec-KubePod - Execute commands in pods
    # ===============================================

    <#
    .SYNOPSIS
        Executes commands in Kubernetes pods.
    

    .DESCRIPTION
        Runs commands inside Kubernetes pods using kubectl exec.
        Supports interactive and non-interactive execution.
    

    .PARAMETER Pod
        Pod name or pattern to match.
    

    .PARAMETER Command
        Command to execute. Defaults to shell (/bin/sh or /bin/bash).
    

    .PARAMETER Container
        Optional container name if pod has multiple containers.
    

    .PARAMETER Namespace
        Kubernetes namespace. Defaults to current namespace.
    

    .PARAMETER Interactive
        Run command interactively (default: false).
    

    .PARAMETER Tty
        Allocate a TTY for the command (default: false).
    

    .OUTPUTS
        System.String. Command output.

    .EXAMPLE
        Exec-KubePod -Pod "my-app" -Command "ls -la"
        
        Executes ls -la in my-app pod.
    

    .EXAMPLE
        Exec-KubePod -Pod "nginx" -Container "web" -Command "/bin/sh" -Interactive -Tty
        
        Opens interactive shell in nginx pod, web container.
    #>
    function Exec-KubePod {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Pod,
            
            [string]$Command = '/bin/sh',
            
            [string]$Container,
            
            [string]$Namespace,
            
            [switch]$Interactive,
            
            [switch]$Tty
        )

        if (-not (Test-CachedCommand 'kubectl')) {
            Invoke-MissingToolWarning -ToolName 'kubectl'
            return
        }

        try {
            $arguments = @('exec', $Pod)
            
            if ($Container) {
                $arguments += '-c', $Container
            }
            
            if ($Namespace) {
                $arguments += '-n', $Namespace
            }
            
            if ($Interactive -or $Tty) {
                $arguments += '-it'
            }
            
            $arguments += '--', $Command

            $output = & kubectl $arguments 2>&1
            if ($LASTEXITCODE -eq 0) {
                return $output
            }
            else {
                Write-Error "Failed to execute command in pod. Exit code: $LASTEXITCODE"
                return ""
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "kubernetes.pod.exec" -Context @{
                    pod       = $Pod
                    container = $Container
                    namespace = $Namespace
                    command   = $Command
                }
            }
            else {
                Write-Error "Failed to run kubectl exec: $_"
            }
            return ""
        }
    }

    # ===============================================
    # PortForward-KubeService - Port forwarding
    # ===============================================

    <#
    .SYNOPSIS
        Forwards ports from Kubernetes services or pods to local machine.
    

    .DESCRIPTION
        Creates port forwarding from Kubernetes resources to local ports.
        Supports both services and pods.
    

    .PARAMETER Resource
        Resource name (pod or service).
    

    .PARAMETER ResourceType
        Resource type: pod or service. Defaults to pod.
    

    .PARAMETER LocalPort
        Local port to forward to. Defaults to same as remote port.
    

    .PARAMETER RemotePort
        Remote port to forward from. Required for services.
    

    .PARAMETER Namespace
        Kubernetes namespace. Defaults to current namespace.
    

    .PARAMETER Address
        Local address to bind to. Defaults to localhost.
    

    .OUTPUTS
        System.String. Port forwarding status or process information.

    .EXAMPLE
        PortForward-KubeService -Resource "my-pod" -LocalPort 8080 -RemotePort 80
        
        Forwards local port 8080 to pod port 80.
    

    .EXAMPLE
        PortForward-KubeService -Resource "my-service" -ResourceType "service" -LocalPort 8080 -RemotePort 80
        
        Forwards local port 8080 to service port 80.
    #>
    function PortForward-KubeService {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Resource,
            
            [ValidateSet('pod', 'service')]
            [string]$ResourceType = 'pod',
            
            [int]$LocalPort,
            
            [int]$RemotePort,
            
            [string]$Namespace,
            
            [string]$Address = 'localhost'
        )

        if (-not (Test-CachedCommand 'kubectl')) {
            Invoke-MissingToolWarning -ToolName 'kubectl'
            return
        }

        if ($ResourceType -eq 'service' -and -not $RemotePort) {
            Write-Error "RemotePort is required when forwarding from a service"
            return
        }

        try {
            $arguments = @('port-forward')
            
            if ($Namespace) {
                $arguments += '-n', $Namespace
            }
            
            $arguments += '--address', $Address
            
            if ($ResourceType -eq 'service') {
                $arguments += "service/$Resource"
            }
            else {
                $arguments += $Resource
            }
            
            if ($LocalPort -and $RemotePort) {
                $arguments += "${LocalPort}:${RemotePort}"
            }
            elseif ($RemotePort) {
                $arguments += $RemotePort.ToString()
            }
            elseif ($LocalPort) {
                $arguments += $LocalPort.ToString()
            }

            Write-Host "Forwarding port from $ResourceType/$Resource..." -ForegroundColor Green
            Write-Host "Press Ctrl+C to stop forwarding" -ForegroundColor Yellow
            
            & kubectl $arguments
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "kubernetes.port-forward" -Context @{
                    resource      = $Resource
                    resource_type = $ResourceType
                    local_port    = $LocalPort
                    remote_port   = $RemotePort
                    namespace     = $Namespace
                }
            }
            else {
                Write-Error "Failed to forward port: $_"
            }
        }
    }

    # ===============================================
    # Describe-KubeResource - Resource descriptions
    # ===============================================

    <#
    .SYNOPSIS
        Gets detailed description of Kubernetes resources.
    

    .DESCRIPTION
        Provides enhanced describe functionality for Kubernetes resources
        with better formatting and filtering options.
    

    .PARAMETER ResourceType
        Kubernetes resource type (e.g., pods, services, deployments).
    

    .PARAMETER ResourceName
        Resource name. If not specified, describes all resources of the type.
    

    .PARAMETER Namespace
        Kubernetes namespace. Defaults to current namespace.
    

    .PARAMETER ShowEvents
        Include events in the description (default: true).
    

    .PARAMETER ShowYaml
        Show resource YAML instead of describe output.
    

    .OUTPUTS
        System.String. Resource description or YAML.

    .EXAMPLE
        Describe-KubeResource -ResourceType "pods" -ResourceName "my-pod"
        
        Describes the my-pod pod.
    

    .EXAMPLE
        Describe-KubeResource -ResourceType "deployments" -Namespace "production" -ShowYaml
        
        Shows YAML for all deployments in production namespace.
    #>
    function Describe-KubeResource {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$ResourceType,
            
            [string]$ResourceName,
            
            [string]$Namespace,
            
            [switch]$ShowEvents = $true,
            
            [switch]$ShowYaml
        )

        if (-not (Test-CachedCommand 'kubectl')) {
            Invoke-MissingToolWarning -ToolName 'kubectl'
            return
        }

        try {
            if ($ShowYaml) {
                $arguments = @('get', $ResourceType)
                
                if ($ResourceName) {
                    $arguments += $ResourceName
                }
                
                if ($Namespace) {
                    $arguments += '-n', $Namespace
                }
                
                $arguments += '-o', 'yaml'
                
                $output = & kubectl $arguments 2>&1
                if ($LASTEXITCODE -eq 0) {
                    return $output
                }
                else {
                    Write-Error "Failed to get resource YAML. Exit code: $LASTEXITCODE"
                    return ""
                }
            }
            else {
                $arguments = @('describe', $ResourceType)
                
                if ($ResourceName) {
                    $arguments += $ResourceName
                }
                
                if ($Namespace) {
                    $arguments += '-n', $Namespace
                }
                
                $output = & kubectl $arguments 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    if (-not $ShowEvents) {
                        # Remove Events section from output
                        $lines = $output -split "`n"
                        $result = @()
                        $skipEvents = $false
                        foreach ($line in $lines) {
                            if ($line -match '^Events:') {
                                $skipEvents = $true
                            }
                            if (-not $skipEvents) {
                                $result += $line
                            }
                        }
                        return $result -join "`n"
                    }
                    return $output
                }
                else {
                    Write-Error "Failed to describe resource. Exit code: $LASTEXITCODE"
                    return ""
                }
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "kubernetes.resource.describe" -Context @{
                    resource_type = $ResourceType
                    resource_name = $ResourceName
                    namespace     = $Namespace
                    show_events   = $ShowEvents.IsPresent
                    show_yaml     = $ShowYaml.IsPresent
                }
            }
            else {
                Write-Error "Failed to run kubectl describe: $_"
            }
            return ""
        }
    }

    # ===============================================
    # Apply-KubeManifests - Apply multiple manifests
    # ===============================================

    <#
    .SYNOPSIS
        Applies multiple Kubernetes manifest files.
    

    .DESCRIPTION
        Applies Kubernetes manifests from files or directories.
        Supports recursive directory processing and dry-run mode.
    

    .PARAMETER Path
        Path to manifest file or directory containing manifests.
    

    .PARAMETER Recursive
        Process directories recursively (default: false).
    

    .PARAMETER DryRun
        Perform a dry-run without actually applying (default: false).
    

    .PARAMETER Namespace
        Kubernetes namespace to apply to. Overrides namespace in manifests.
    

    .PARAMETER ServerSide
        Use server-side apply (default: false).
    

    .PARAMETER Force
        Force apply even if resources already exist (default: false).
    

    .OUTPUTS
        System.String. Apply output from kubectl.

    .EXAMPLE
        Apply-KubeManifests -Path "manifests/"
        
        Applies all manifests in the manifests directory.
    

    .EXAMPLE
        Apply-KubeManifests -Path "k8s/" -Recursive -DryRun
        
        Performs dry-run of all manifests recursively.
    

    .EXAMPLE
        Apply-KubeManifests -Path "deployment.yaml" -Namespace "production" -ServerSide
        
        Applies deployment.yaml to production namespace using server-side apply.
    #>
    function Apply-KubeManifests {
        [CmdletBinding(SupportsShouldProcess = $true)]
        [OutputType([string])]
        param(
            [Parameter(Mandatory = $true)]
            [string]$Path,
            
            [switch]$Recursive,
            
            [switch]$DryRun,
            
            [string]$Namespace,
            
            [switch]$ServerSide,
            
            [switch]$Force
        )

        if (-not (Test-CachedCommand 'kubectl')) {
            Invoke-MissingToolWarning -ToolName 'kubectl'
            return
        }

        if (-not (Test-Path -LiteralPath $Path)) {
            Write-Error "Path not found: $Path"
            return
        }

        try {
            $arguments = @('apply')
            
            if ($DryRun) {
                $arguments += '--dry-run=client'
            }
            
            if ($Namespace) {
                $arguments += '-n', $Namespace
            }
            
            if ($ServerSide) {
                $arguments += '--server-side'
            }
            
            if ($Force) {
                $arguments += '--force'
            }
            
            if ($Recursive -and (Test-Path -LiteralPath $Path -PathType Container)) {
                $arguments += '-R', '-f', $Path
            }
            else {
                $arguments += '-f', $Path
            }

            if (-not $PSCmdlet.ShouldProcess($Path, "Apply Kubernetes manifests")) {
                return
            }

            $output = & kubectl $arguments 2>&1
            if ($LASTEXITCODE -eq 0) {
                return $output
            }
            else {
                Write-Error "Failed to apply manifests. Exit code: $LASTEXITCODE"
                return ""
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName "kubernetes.manifests.apply" -Context @{
                    path        = $Path
                    recursive   = $Recursive.IsPresent
                    dry_run     = $DryRun.IsPresent
                    namespace   = $Namespace
                    server_side = $ServerSide.IsPresent
                    force       = $Force.IsPresent
                }
            }
            else {
                Write-Error "Failed to run kubectl apply: $_"
            }
            return ""
        }
    }

    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'kube-workloads'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'kube-workloads' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load kube-workloads: "
    }
}
