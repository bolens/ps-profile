# ===============================================
# helm.ps1
# Helm Kubernetes package manager helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: cloud, containers, development

<#
.SYNOPSIS
    Helm Kubernetes package manager helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Helm operations.
    Functions check for helm availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Helm
    Author: PowerShell Profile
#>

# Helm execute - run helm with arguments
<#
.SYNOPSIS
    Executes Helm commands.

.DESCRIPTION
    Wrapper function for Helm CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to helm.

.EXAMPLE
    Invoke-Helm --version

.EXAMPLE
    Invoke-Helm list
#>
function Invoke-Helm {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand helm) {
        helm @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'helm' -InstallHint 'Install with: scoop install helm'
    }
}

# Helm install - install Helm charts
<#
.SYNOPSIS
    Installs Helm charts.

.DESCRIPTION
    Wrapper for helm install command.

.PARAMETER Arguments
    Arguments to pass to helm install.

.EXAMPLE
    Install-HelmChart my-release ./my-chart

.EXAMPLE
    Install-HelmChart my-release bitnami/nginx
#>
function Install-HelmChart {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand helm) {
        helm install @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'helm' -InstallHint 'Install with: scoop install helm'
    }
}

# Helm upgrade - upgrade Helm releases
<#
.SYNOPSIS
    Upgrades Helm releases.

.DESCRIPTION
    Wrapper for helm upgrade command.

.PARAMETER Arguments
    Arguments to pass to helm upgrade.

.EXAMPLE
    Update-HelmRelease my-release ./my-chart

.EXAMPLE
    Update-HelmRelease my-release bitnami/nginx
#>
function Update-HelmRelease {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand helm) {
        helm upgrade @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'helm' -InstallHint 'Install with: scoop install helm'
    }
}

# Helm list - list Helm releases
<#
.SYNOPSIS
    Lists Helm releases.

.DESCRIPTION
    Wrapper for helm list command.

.PARAMETER Arguments
    Arguments to pass to helm list.

.EXAMPLE
    Get-HelmReleases

.EXAMPLE
    Get-HelmReleases --all-namespaces
#>
function Get-HelmReleases {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand helm) {
        helm list @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'helm' -InstallHint 'Install with: scoop install helm'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'helm' -Target 'Invoke-Helm'
    Set-AgentModeAlias -Name 'helm-install' -Target 'Install-HelmChart'
    Set-AgentModeAlias -Name 'helm-upgrade' -Target 'Update-HelmRelease'
    Set-AgentModeAlias -Name 'helm-list' -Target 'Get-HelmReleases'
}
else {
    Set-Alias -Name 'helm' -Value 'Invoke-Helm' -ErrorAction SilentlyContinue
    Set-Alias -Name 'helm-install' -Value 'Install-HelmChart' -ErrorAction SilentlyContinue
    Set-Alias -Name 'helm-upgrade' -Value 'Update-HelmRelease' -ErrorAction SilentlyContinue
    Set-Alias -Name 'helm-list' -Value 'Get-HelmReleases' -ErrorAction SilentlyContinue
}
