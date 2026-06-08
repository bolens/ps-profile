# ===============================================
# cloud-azure.ps1
# Azure cloud helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, azure
<#
.SYNOPSIS
    Azure cloud helpers
.DESCRIPTION
    Set-AzureSubscription wrapper.
.NOTES
    Loaded by cloud-enhanced.ps1 or directly.
#>
try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'cloud-azure') { return }
    }
    # ===============================================
    # Set-AzureSubscription - Switch Azure subscription
    # ===============================================

    <#
    .SYNOPSIS
        Switches the active Azure subscription.
    

    .DESCRIPTION
        Changes the active Azure subscription for the current session.
        Uses Azure CLI to list and set subscriptions.
    

    .PARAMETER SubscriptionId
        Subscription ID or name to switch to.
    

    .PARAMETER List
        List all available subscriptions instead of switching.
    

    .OUTPUTS
        System.String. Subscription information or list of subscriptions.

    .EXAMPLE
        Set-AzureSubscription -SubscriptionId "my-subscription-id"
        
        Switches to the specified subscription.
    

    .EXAMPLE
        Set-AzureSubscription -List
        
        Lists all available subscriptions.
    #>
    function Set-AzureSubscription {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [string]$SubscriptionId,
            
            [switch]$List
        )

        if (-not (Test-CachedCommand 'az')) {
            Invoke-MissingToolWarning -ToolName 'azure-cli' -Tool 'az'
            return
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'cloud.azure.subscription.manage' -Context @{
                action          = if ($List) { 'list' } elseif ($SubscriptionId) { 'set' } else { 'show' }
                subscription_id = $SubscriptionId
            } -ScriptBlock {
                if ($List) {
                    $output = & az account list --output table 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to list subscriptions. Exit code: $LASTEXITCODE"
                    }
                    return $output
                }
                elseif ($SubscriptionId) {
                    $output = & az account set --subscription $SubscriptionId 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to switch subscription. Exit code: $LASTEXITCODE"
                    }
                    Write-Host "Switched to subscription: $SubscriptionId" -ForegroundColor Green
                    return $output
                }
                else {
                    # Show current subscription
                    $output = & az account show --output table 2>&1
                    if ($LASTEXITCODE -ne 0) {
                        throw "Failed to get current subscription. Exit code: $LASTEXITCODE"
                    }
                    return $output
                }
            }
        }
        else {
            try {
                if ($List) {
                    $output = & az account list --output table 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Failed to list subscriptions. Exit code: $LASTEXITCODE"
                    }
                }
                elseif ($SubscriptionId) {
                    $output = & az account set --subscription $SubscriptionId 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        Write-Host "Switched to subscription: $SubscriptionId" -ForegroundColor Green
                        return $output
                    }
                    else {
                        Write-Error "Failed to switch subscription. Exit code: $LASTEXITCODE"
                    }
                }
                else {
                    # Show current subscription
                    $output = & az account show --output table 2>&1
                    if ($LASTEXITCODE -eq 0) {
                        return $output
                    }
                    else {
                        Write-Error "Failed to get current subscription. Exit code: $LASTEXITCODE"
                    }
                }
            }
            catch {
                Write-Error "Failed to run az account command: $_"
            }
        }
    }
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'cloud-azure'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'cloud-azure' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load cloud-azure: "
    }
}
