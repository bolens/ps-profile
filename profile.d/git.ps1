# ===============================================
# git.ps1
# Git helper functions and aliases
# ===============================================
# Tier: essential
# Dependencies: bootstrap, env

# This fragment consolidates functionality from the old 11-git.ps1 and 44-git.ps1 fragments
# It provides both lightweight stubs and full Git module loading

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'git') { return }
    }

    # These are lightweight stubs that call `git` at runtime
    # and won't probe for `git` during dot-source

    # Git current branch - get current branch name
    if (-not (Test-Path Function:Get-GitCurrentBranch -ErrorAction SilentlyContinue)) {
        Set-Item -Path Function:Get-GitCurrentBranch -Value { git rev-parse --abbrev-ref HEAD 2>$null } -Force | Out-Null
        Set-Alias -Name Git-CurrentBranch -Value Get-GitCurrentBranch -ErrorAction SilentlyContinue
    }

    # Git status short - show concise status
    if (-not (Test-Path Function:Get-GitStatusShort -ErrorAction SilentlyContinue)) {
        Set-Item -Path Function:Get-GitStatusShort -Value { git status --porcelain 2>$null } -Force | Out-Null
        Set-Alias -Name Git-StatusShort -Value Get-GitStatusShort -ErrorAction SilentlyContinue
    }

    # Git prompt segment - show current branch in prompt
    if (-not (Test-Path Function:Format-PromptGitSegment -ErrorAction SilentlyContinue)) {
        Set-Item -Path Function:Format-PromptGitSegment -Value { $b = (Get-GitCurrentBranch) -as [string]; if ($b) { return "($b)" }; return '' } -Force | Out-Null
        Set-Alias -Name Prompt-GitSegment -Value Format-PromptGitSegment -ErrorAction SilentlyContinue
    }

    # ===============================================
    # Git Modules - DEFERRED LOADING
    # ===============================================
    # Modules are now loaded on-demand via Ensure-Git function.
    # See files-module-registry.ps1 for module mappings.
    #
    # OLD EAGER LOADING CODE (commented out for performance):
    # Previously loaded 4 modules eagerly at startup, adding 200-500ms to load time.
    # Now modules are loaded only when Ensure-Git is called.
    
    # Lazy bulk initializer for Git utility functions
    <#
    .SYNOPSIS
        Sets up all Git utility functions when any of them is called for the first time.
        This lazy loading approach improves profile startup performance.
        Loads Git modules from the git-modules subdirectory.
    #>
    function Ensure-Git {
        if ($global:GitInitialized) { return }

        # Load modules from registry (deferred loading - only loads when this function is called)
        if (Get-Command Load-EnsureModules -ErrorAction SilentlyContinue) {
            Load-EnsureModules -EnsureFunctionName 'Ensure-Git' -BaseDir $PSScriptRoot
        }

        # Mark as initialized
        $global:GitInitialized = $true
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'git'
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: git" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load git fragment: $($_.Exception.Message)"
        }
    }
}
