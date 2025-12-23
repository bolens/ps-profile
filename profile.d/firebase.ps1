# ===============================================
# firebase.ps1
# Firebase CLI helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

<#
.SYNOPSIS
    Firebase CLI helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Firebase operations.
    Functions check for firebase availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Firebase
    Author: PowerShell Profile
#>

# Firebase execute - run firebase with arguments
<#
.SYNOPSIS
    Executes Firebase CLI commands.

.DESCRIPTION
    Wrapper function for Firebase CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to firebase.

.EXAMPLE
    Invoke-Firebase --version

.EXAMPLE
    Invoke-Firebase login
#>
function Invoke-Firebase {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand firebase) {
        firebase @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'firebase' -InstallHint 'Install with: scoop install firebase-tools'
    }
}

# Firebase deploy - deploy to Firebase hosting
<#
.SYNOPSIS
    Deploys to Firebase hosting.

.DESCRIPTION
    Wrapper for firebase deploy command.

.PARAMETER Arguments
    Arguments to pass to firebase deploy.

.EXAMPLE
    Publish-FirebaseDeployment

.EXAMPLE
    Publish-FirebaseDeployment --only hosting
#>
function Publish-FirebaseDeployment {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand firebase) {
        firebase deploy @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'firebase' -InstallHint 'Install with: scoop install firebase-tools'
    }
}

# Firebase serve - start local development server
<#
.SYNOPSIS
    Starts Firebase local development server.

.DESCRIPTION
    Wrapper for firebase serve command.

.PARAMETER Arguments
    Arguments to pass to firebase serve.

.EXAMPLE
    Start-FirebaseServer

.EXAMPLE
    Start-FirebaseServer --only hosting
#>
function Start-FirebaseServer {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand firebase) {
        firebase serve @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'firebase' -InstallHint 'Install with: scoop install firebase-tools'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'fb' -Target 'Invoke-Firebase'
    Set-AgentModeAlias -Name 'fb-deploy' -Target 'Publish-FirebaseDeployment'
    Set-AgentModeAlias -Name 'fb-serve' -Target 'Start-FirebaseServer'
}
else {
    Set-Alias -Name 'fb' -Value 'Invoke-Firebase' -ErrorAction SilentlyContinue
    Set-Alias -Name 'fb-deploy' -Value 'Publish-FirebaseDeployment' -ErrorAction SilentlyContinue
    Set-Alias -Name 'fb-serve' -Value 'Start-FirebaseServer' -ErrorAction SilentlyContinue
}
