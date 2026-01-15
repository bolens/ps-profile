# ===============================================
# azure.ps1
# Azure CLI helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: cloud, development

<#
.SYNOPSIS
    Azure CLI helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Azure CLI operations.
    Functions check for az/azd availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Azure
    Author: PowerShell Profile
#>

# Azure execute - run az with arguments
<#
.SYNOPSIS
    Executes Azure CLI commands.

.DESCRIPTION
    Wrapper function for Azure CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to az.

.EXAMPLE
    Invoke-Azure --version

.EXAMPLE
    Invoke-Azure account list
#>
function Invoke-Azure {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    # Use base module if available, otherwise fallback to direct execution
    if (Get-Command Invoke-CloudCommand -ErrorAction SilentlyContinue) {
        return Invoke-CloudCommand -CommandName 'az' -Arguments $Arguments -ParseJson $false -ErrorOnNonZeroExit $false -InstallHint 'Install with: scoop install azure-cli'
    }
    else {
        # Fallback to original implementation
        if (Test-CachedCommand az) {
            az @Arguments
        }
        else {
            Write-MissingToolWarning -Tool 'az' -InstallHint 'Install with: scoop install azure-cli'
        }
    }
}

# Azure Developer CLI - Azure development tools
<#
.SYNOPSIS
    Executes Azure Developer CLI commands.

.DESCRIPTION
    Wrapper function for Azure Developer CLI (azd) that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to azd.

.EXAMPLE
    Invoke-AzureDeveloper --version

.EXAMPLE
    Invoke-AzureDeveloper init
#>
function Invoke-AzureDeveloper {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand azd) {
        azd @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'azd' -InstallHint 'Install with: scoop install azure-developer-cli'
    }
}

# Azure login - authenticate with Azure CLI
<#
.SYNOPSIS
    Authenticates with Azure CLI.

.DESCRIPTION
    Wrapper for az login command.

.EXAMPLE
    Connect-AzureAccount
#>
function Connect-AzureAccount {
    [CmdletBinding()]
    param()
    
    # Use base module if available
    if (Get-Command Invoke-CloudCommand -ErrorAction SilentlyContinue) {
        return Invoke-CloudCommand -CommandName 'az' -Arguments @('login') -OperationName "azure.account.connect" -ParseJson $false -ErrorOnNonZeroExit $false -InstallHint 'Install with: scoop install azure-cli'
    }
    else {
        # Fallback to original implementation
        if (Test-CachedCommand az) {
            az login
        }
        else {
            Write-MissingToolWarning -Tool 'Azure CLI (az)' -InstallHint 'Install with: scoop install azure-cli'
        }
    }
}

# Azure Developer CLI up - provision and deploy
<#
.SYNOPSIS
    Provisions and deploys using Azure Developer CLI.

.DESCRIPTION
    Wrapper for azd up command.

.PARAMETER Arguments
    Arguments to pass to azd up.

.EXAMPLE
    Start-AzureDeveloperUp

.EXAMPLE
    Start-AzureDeveloperUp --location eastus
#>
function Start-AzureDeveloperUp {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand azd) {
        azd up @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'Azure Developer CLI (azd)' -InstallHint 'Install with: scoop install azure-developer-cli'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'az' -Target 'Invoke-Azure'
    Set-AgentModeAlias -Name 'azd' -Target 'Invoke-AzureDeveloper'
    Set-AgentModeAlias -Name 'az-login' -Target 'Connect-AzureAccount'
    Set-AgentModeAlias -Name 'azd-up' -Target 'Start-AzureDeveloperUp'
}
else {
    Set-Alias -Name 'az' -Value 'Invoke-Azure' -ErrorAction SilentlyContinue
    Set-Alias -Name 'azd' -Value 'Invoke-AzureDeveloper' -ErrorAction SilentlyContinue
    Set-Alias -Name 'az-login' -Value 'Connect-AzureAccount' -ErrorAction SilentlyContinue
    Set-Alias -Name 'azd-up' -Value 'Start-AzureDeveloperUp' -ErrorAction SilentlyContinue
}
