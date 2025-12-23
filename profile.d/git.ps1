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

    # Load Git utility modules (loaded eagerly as they provide commonly-used Git helpers)
    # Use standardized module loading if available, otherwise fall back to manual loading
    if (Get-Command Import-FragmentModules -ErrorAction SilentlyContinue) {
        try {
            $modules = @(
                @{ ModulePath = @('git-modules', 'core', 'git-helpers.ps1'); Context = 'Fragment: git (git-helpers.ps1)' },
                @{ ModulePath = @('git-modules', 'core', 'git-basic.ps1'); Context = 'Fragment: git (git-basic.ps1)' },
                @{ ModulePath = @('git-modules', 'core', 'git-advanced.ps1'); Context = 'Fragment: git (git-advanced.ps1)' },
                @{ ModulePath = @('git-modules', 'integrations', 'git-github.ps1'); Context = 'Fragment: git (git-github.ps1)' }
            )
            
            $result = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules
            
            if ($env:PS_PROFILE_DEBUG -and $result.FailureCount -gt 0) {
                Write-Verbose "Loaded $($result.SuccessCount) git modules (failed: $($result.FailureCount))"
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
    }
    else {
        # Fallback: manual loading for environments where Import-FragmentModules is not yet available
        try {
            $gitModulesDir = Join-Path $PSScriptRoot 'git-modules'
            if ($gitModulesDir -and -not [string]::IsNullOrWhiteSpace($gitModulesDir) -and (Test-Path -LiteralPath $gitModulesDir)) {
                # Core Git operations (helpers, basic commands, advanced workflows)
                $coreDir = Join-Path $gitModulesDir 'core'
                try { . (Join-Path $coreDir 'git-helpers.ps1') }
                catch { 
                    if ($env:PS_PROFILE_DEBUG) { 
                        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                            Write-ProfileError -ErrorRecord $_ -Context "Fragment: git (git-helpers)" -Category 'Fragment'
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
                            Write-ProfileError -ErrorRecord $_ -Context "Fragment: git (git-basic)" -Category 'Fragment'
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
                            Write-ProfileError -ErrorRecord $_ -Context "Fragment: git (git-advanced)" -Category 'Fragment'
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
                            Write-ProfileError -ErrorRecord $_ -Context "Fragment: git (git-github)" -Category 'Fragment'
                        }
                        else {
                            Write-Warning "Failed to load git-github.ps1: $($_.Exception.Message)" 
                        }
                    } 
                }
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
