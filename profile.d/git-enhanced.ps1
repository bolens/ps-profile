# ===============================================
# git-enhanced.ps1
# Enhanced Git helpers (modular loader)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env, git

<#
.SYNOPSIS
    Enhanced Git helpers loader.

.DESCRIPTION
    Loads modular Git helper modules from git-modules/enhanced/:
    - git-changelog.ps1: git-cliff changelog generation
    - git-gui.ps1: Tower, Kraken, GitButler, Jujutsu launchers
    - git-workflow.ps1: worktrees, sync, branch cleanup, stats

.NOTES
    Replaces the monolithic git-enhanced.ps1 removed in modular migration.
#>

try {
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'git-enhanced') { return }
    }

    $modules = @(
        @{ ModulePath = @('git-modules', 'enhanced', 'git-changelog.ps1'); Context = 'Fragment: git-enhanced (git-changelog.ps1)' }
        @{ ModulePath = @('git-modules', 'enhanced', 'git-gui.ps1'); Context = 'Fragment: git-enhanced (git-gui.ps1)' }
        @{ ModulePath = @('git-modules', 'enhanced', 'git-workflow.ps1'); Context = 'Fragment: git-enhanced (git-workflow.ps1)' }
    )

    $null = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules

    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'git-enhanced'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context 'Fragment: git-enhanced' -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load git-enhanced fragment: $($_.Exception.Message)"
    }
}
