# ===============================================
# cloud-enhanced.ps1
# Enhanced cloud deployment helpers (modular loader)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Enhanced cloud deployment helpers loader.

.DESCRIPTION
    Loads modular cloud helper modules from cloud-modules/:
    - cloud-azure.ps1: Azure subscription switching
    - cloud-gcp.ps1: GCP project switching
    - cloud-deploy.ps1: Doppler, Heroku, Vercel, Netlify deploy helpers

.NOTES
    Replaces the monolithic cloud-enhanced.ps1 removed in modular migration.
#>

try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'cloud-enhanced') { return }
    }

    $modules = @(
        @{ ModulePath = @('cloud-modules', 'cloud-azure.ps1'); Context = 'Fragment: cloud-enhanced (cloud-azure.ps1)' }
        @{ ModulePath = @('cloud-modules', 'cloud-gcp.ps1'); Context = 'Fragment: cloud-enhanced (cloud-gcp.ps1)' }
        @{ ModulePath = @('cloud-modules', 'cloud-deploy.ps1'); Context = 'Fragment: cloud-enhanced (cloud-deploy.ps1)' }
    )

    $null = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules

    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'cloud-enhanced'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context 'Fragment: cloud-enhanced' -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load cloud-enhanced fragment: $($_.Exception.Message)"
    }
}
