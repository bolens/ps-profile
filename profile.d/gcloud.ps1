# ===============================================
# gcloud.ps1
# Google Cloud CLI helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: cloud, development

<#
.SYNOPSIS
    Google Cloud CLI helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Google Cloud CLI operations.
    Functions check for gcloud availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.GCloud
    Author: PowerShell Profile
#>

# Google Cloud execute - run gcloud with arguments
<#
.SYNOPSIS
    Executes Google Cloud CLI commands.

.DESCRIPTION
    Wrapper function for Google Cloud CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to gcloud.

.EXAMPLE
    Invoke-GCloud --version

.EXAMPLE
    Invoke-GCloud config list
#>
function Invoke-GCloud {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand gcloud) {
        gcloud @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'gcloud' -InstallHint 'Install with: scoop install gcloud'
    }
}

# Google Cloud auth - manage authentication
<#
.SYNOPSIS
    Manages Google Cloud authentication.

.DESCRIPTION
    Wrapper for gcloud auth commands.

.PARAMETER Arguments
    Arguments to pass to gcloud auth.

.EXAMPLE
    Set-GCloudAuth login

.EXAMPLE
    Set-GCloudAuth list
#>
function Set-GCloudAuth {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand gcloud) {
        gcloud auth @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'Google Cloud CLI (gcloud)' -InstallHint 'Install with: scoop install gcloud'
    }
}

# Google Cloud config - manage configuration
<#
.SYNOPSIS
    Manages Google Cloud configuration.

.DESCRIPTION
    Wrapper for gcloud config commands.

.PARAMETER Arguments
    Arguments to pass to gcloud config.

.EXAMPLE
    Set-GCloudConfig list

.EXAMPLE
    Set-GCloudConfig set project my-project
#>
function Set-GCloudConfig {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand gcloud) {
        gcloud config @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'Google Cloud CLI (gcloud)' -InstallHint 'Install with: scoop install gcloud'
    }
}

# Google Cloud projects - manage GCP projects
<#
.SYNOPSIS
    Manages Google Cloud Platform projects.

.DESCRIPTION
    Wrapper for gcloud projects commands.

.PARAMETER Arguments
    Arguments to pass to gcloud projects.

.EXAMPLE
    Get-GCloudProjects list

.EXAMPLE
    Get-GCloudProjects describe my-project
#>
function Get-GCloudProjects {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand gcloud) {
        gcloud projects @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'Google Cloud CLI (gcloud)' -InstallHint 'Install with: scoop install gcloud'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'gcloud' -Target 'Invoke-GCloud'
    Set-AgentModeAlias -Name 'gcloud-auth' -Target 'Set-GCloudAuth'
    Set-AgentModeAlias -Name 'gcloud-config' -Target 'Set-GCloudConfig'
    Set-AgentModeAlias -Name 'gcloud-projects' -Target 'Get-GCloudProjects'
}
else {
    Set-Alias -Name 'gcloud' -Value 'Invoke-GCloud' -ErrorAction SilentlyContinue
    Set-Alias -Name 'gcloud-auth' -Value 'Set-GCloudAuth' -ErrorAction SilentlyContinue
    Set-Alias -Name 'gcloud-config' -Value 'Set-GCloudConfig' -ErrorAction SilentlyContinue
    Set-Alias -Name 'gcloud-projects' -Value 'Get-GCloudProjects' -ErrorAction SilentlyContinue
}
