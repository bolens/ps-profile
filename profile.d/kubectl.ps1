# ===============================================
# kubectl.ps1
# Small kubectl shorthands and helpers
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env
# Environment: cloud, containers, development

<#
.SYNOPSIS
    kubectl helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common kubectl operations.
    Functions check for kubectl availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Kubectl
    Author: PowerShell Profile
#>

# kubectl execute - run kubectl with arguments
<#
.SYNOPSIS
    Executes kubectl with the specified arguments.

.DESCRIPTION
    Wrapper function for kubectl that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to kubectl.

.EXAMPLE
    Invoke-Kubectl version

.EXAMPLE
    Invoke-Kubectl get pods
#>
function Invoke-Kubectl {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand kubectl) {
        kubectl @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'kubectl'
    }
}

# kubectl context switcher - switch Kubernetes context
<#
.SYNOPSIS
    Switches the current Kubernetes context.

.DESCRIPTION
    Changes the active Kubernetes context using kubectl config use-context.

.PARAMETER ContextName
    Name of the context to switch to.

.EXAMPLE
    Set-KubectlContext my-context
#>
function Set-KubectlContext {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$ContextName
    )
    
    if (Test-CachedCommand kubectl) {
        kubectl config use-context $ContextName
    }
    else {
        Invoke-MissingToolWarning -ToolName 'kubectl'
    }
}

# kubectl get - get Kubernetes resources
<#
.SYNOPSIS
    Gets Kubernetes resources.

.DESCRIPTION
    Wrapper for kubectl get command.

.PARAMETER Arguments
    Arguments to pass to kubectl get.

.EXAMPLE
    Get-KubectlResource pods

.EXAMPLE
    Get-KubectlResource pods -n default
#>
function Get-KubectlResource {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand kubectl) {
        kubectl get @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'kubectl'
    }
}

# kubectl describe - describe Kubernetes resources
<#
.SYNOPSIS
    Describes Kubernetes resources.

.DESCRIPTION
    Wrapper for kubectl describe command.

.PARAMETER Arguments
    Arguments to pass to kubectl describe.

.EXAMPLE
    Describe-KubectlResource pod my-pod

.EXAMPLE
    Describe-KubectlResource pod my-pod -n default
#>
function Describe-KubectlResource {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand kubectl) {
        kubectl describe @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'kubectl'
    }
}

# kubectl context - show current context
<#
.SYNOPSIS
    Gets the current Kubernetes context.

.DESCRIPTION
    Returns the name of the currently active Kubernetes context.

.EXAMPLE
    Get-KubectlContext
#>
function Get-KubectlContext {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand kubectl) {
        kubectl config current-context
    }
    else {
        Invoke-MissingToolWarning -ToolName 'kubectl'
    }
}

# Create aliases for short forms
Set-AgentModeAlias -Name 'k' -Target 'Invoke-Kubectl'
Set-AgentModeAlias -Name 'kn' -Target 'Set-KubectlContext'
Set-AgentModeAlias -Name 'kg' -Target 'Get-KubectlResource'
Set-AgentModeAlias -Name 'kd' -Target 'Describe-KubectlResource'
Set-AgentModeAlias -Name 'kctx' -Target 'Get-KubectlContext'
