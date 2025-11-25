# ===============================================
# 11-git.ps1
# Git helper functions and aliases
# =======================================

try {
    # Load Git utility modules (loaded eagerly as they provide commonly-used Git helpers)
    $gitModulesDir = Join-Path $PSScriptRoot 'git-modules'
    if (Test-Path $gitModulesDir) {
        # Core Git operations (helpers, basic commands, advanced workflows)
        $coreDir = Join-Path $gitModulesDir 'core'
        try { . (Join-Path $coreDir 'git-helpers.ps1') }
        catch { 
            if ($env:PS_PROFILE_DEBUG) { 
                if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                    Write-ProfileError -ErrorRecord $_ -Context "Fragment: 11-git (git-helpers)" -Category 'Fragment'
                }
                else {
                    Write-Warning "Failed to load git-helpers.ps1: $($_.Exception.Message)" 
                }
            } 
        }
        
        try { . (Join-Path $coreDir 'git-basic.ps1') }
        catch { 
            if ($env:PS_PROFILE_DEBUG) { 
                if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                    Write-ProfileError -ErrorRecord $_ -Context "Fragment: 11-git (git-basic)" -Category 'Fragment'
                }
                else {
                    Write-Warning "Failed to load git-basic.ps1: $($_.Exception.Message)" 
                }
            } 
        }
        
        try { . (Join-Path $coreDir 'git-advanced.ps1') }
        catch { 
            if ($env:PS_PROFILE_DEBUG) { 
                if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                    Write-ProfileError -ErrorRecord $_ -Context "Fragment: 11-git (git-advanced)" -Category 'Fragment'
                }
                else {
                    Write-Warning "Failed to load git-advanced.ps1: $($_.Exception.Message)" 
                }
            } 
        }
        
        # Git service integrations (GitHub-specific helpers)
        $integrationsDir = Join-Path $gitModulesDir 'integrations'
        try { . (Join-Path $integrationsDir 'git-github.ps1') }
        catch { 
            if ($env:PS_PROFILE_DEBUG) { 
                if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                    Write-ProfileError -ErrorRecord $_ -Context "Fragment: 11-git (git-github)" -Category 'Fragment'
                }
                else {
                    Write-Warning "Failed to load git-github.ps1: $($_.Exception.Message)" 
                }
            } 
        }
    }
}
catch {
    # Error handling for fragment-level failures (module loading errors are handled individually above)
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: 11-git" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load git fragment: $($_.Exception.Message)"
        }
    }
}
