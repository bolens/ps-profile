# ===============================================
# kubernetes-enhanced.ps1
# Enhanced Kubernetes helpers (modular loader)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Enhanced Kubernetes helpers loader.

.DESCRIPTION
    Loads modular Kubernetes helper modules from kubernetes-modules/:
    - kube-context.ps1: context and namespace switching
    - kube-logs.ps1: log tailing (stern/kubectl)
    - kube-workloads.ps1: resources, exec, port-forward, apply
    - kube-console.ps1: minikube and k9s launchers

.NOTES
    Replaces the monolithic kubernetes-enhanced.ps1 removed in modular migration.
#>

try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'kubernetes-enhanced') { return }
    }

    $modules = @(
        @{ ModulePath = @('kubernetes-modules', 'kube-context.ps1'); Context = 'Fragment: kubernetes-enhanced (kube-context.ps1)' }
        @{ ModulePath = @('kubernetes-modules', 'kube-logs.ps1'); Context = 'Fragment: kubernetes-enhanced (kube-logs.ps1)' }
        @{ ModulePath = @('kubernetes-modules', 'kube-workloads.ps1'); Context = 'Fragment: kubernetes-enhanced (kube-workloads.ps1)' }
        @{ ModulePath = @('kubernetes-modules', 'kube-console.ps1'); Context = 'Fragment: kubernetes-enhanced (kube-console.ps1)' }
    )

    if (Get-Command Import-FragmentModules -ErrorAction SilentlyContinue) {
        $null = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules
    }
    else {
        foreach ($entry in $modules) {
            $modulePath = $PSScriptRoot
            foreach ($segment in $entry.ModulePath) {
                $modulePath = Join-Path $modulePath $segment
            }
            if (Test-Path -LiteralPath $modulePath) {
                . $modulePath
            }
            elseif ($env:PS_PROFILE_DEBUG) {
                Write-Warning "kubernetes-enhanced: module not found: $modulePath"
            }
        }
    }

    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'kubernetes-enhanced'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context 'Fragment: kubernetes-enhanced' -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load kubernetes-enhanced fragment: $($_.Exception.Message)"
    }
}
