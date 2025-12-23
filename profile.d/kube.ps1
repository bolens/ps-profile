# ===============================================
# kube.ps1
# kubectl / minikube helpers
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env
# Environment: cloud, containers, development

<#
.SYNOPSIS
    Minikube helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Minikube operations.
    Functions check for minikube availability using Test-HasCommand for efficient
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
    Start-MinikubeCluster

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
        Write-MissingToolWarning -Tool 'minikube' -InstallHint 'Install with: scoop install minikube'
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
    Stop-MinikubeCluster

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
        Write-MissingToolWarning -Tool 'minikube' -InstallHint 'Install with: scoop install minikube'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'minikube-start' -Target 'Start-MinikubeCluster'
    Set-AgentModeAlias -Name 'minikube-stop' -Target 'Stop-MinikubeCluster'
}
else {
    Set-Alias -Name 'minikube-start' -Value 'Start-MinikubeCluster' -ErrorAction SilentlyContinue
    Set-Alias -Name 'minikube-stop' -Value 'Stop-MinikubeCluster' -ErrorAction SilentlyContinue
}
