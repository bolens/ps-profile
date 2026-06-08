# ===============================================
# kube.ps1
# Minikube helpers
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env
# Environment: cloud, containers, development

<#
.SYNOPSIS
    Minikube helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Minikube operations.
    Functions check for minikube availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Minikube
    Author: PowerShell Profile
    
    Note: kubectl shorthands are authoritative in `profile.d/kubectl.ps1`.
#>

# minikube start - start Minikube cluster
<#
.SYNOPSIS
    Starts a Minikube cluster.

.DESCRIPTION
    Wrapper for minikube start command.

.PARAMETER Arguments
    Arguments to pass to minikube start.

.EXAMPLE
    Start-MinikubeCluster --driver=docker
#>
function Start-MinikubeCluster {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand minikube) {
        minikube start @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'minikube'
    }
}

# minikube stop - stop Minikube cluster
<#
.SYNOPSIS
    Stops a Minikube cluster.

.DESCRIPTION
    Wrapper for minikube stop command.

.PARAMETER Arguments
    Arguments to pass to minikube stop.

.EXAMPLE
    Stop-MinikubeCluster --all
#>
function Stop-MinikubeCluster {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand minikube) {
        minikube stop @Arguments
    }
    else {
        Invoke-MissingToolWarning -ToolName 'minikube'
    }
}

# Create aliases for short forms
Set-AgentModeAlias -Name 'minikube-start' -Target 'Start-MinikubeCluster'
Set-AgentModeAlias -Name 'minikube-stop' -Target 'Stop-MinikubeCluster'
