# ===============================================
# lang-rust-build.ps1
# Rust build, dependency updates, and cache management
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Rust build, dependency updates, and cache management.

.DESCRIPTION
    Provides wrapper functions for Rust development tools:
    - Build-RustRelease: Build in release mode with optimizations
    - Update-RustDependencies: Update all Cargo.toml dependencies
    - Clear-CargoCache: Clean up cargo registry/cache

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module enhances rustup.ps1, which provides basic rustup and cargo operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-rust-build') { return }
    }


    # ===============================================
    # cargo build --release - Release build
    # ===============================================

    <#
.SYNOPSIS
        Builds a Rust project in release mode with optimizations.
    

    .DESCRIPTION
        Wrapper function for building Rust projects in release mode. This runs
        'cargo build --release' which enables optimizations and produces smaller,
        faster binaries suitable for production use.
    

    .PARAMETER Arguments
        Additional arguments to pass to cargo build.
        Can be used multiple times or as an array.
    

    .OUTPUTS
        System.String. Output from cargo build execution.

    .EXAMPLE
    Build-RustRelease
        Builds the current project in release mode.
    

    .EXAMPLE
        Build-RustRelease --bin myapp
        Builds a specific binary in release mode.
#>
    function Build-RustRelease {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'cargo')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            Invoke-MissingToolWarning -ToolName 'rustup' -Tool 'cargo' -ToolType 'rust-package'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'rust.cargo.build-release' -Context @{
                has_additional_args = ($null -ne $Arguments)
            } -ScriptBlock {
                $cmdArgs = @('build', '--release')
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                & cargo @cmdArgs 2>&1
            }
        }
        else {
            try {
                $cmdArgs = @('build', '--release')
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                $result = & cargo @cmdArgs 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run cargo build --release: $($_.Exception.Message)"
                return $null
            }
        }
    }

    Set-AgentModeFunction -Name 'Build-RustRelease' -Body ${function:Build-RustRelease}
    if (-not (Get-Alias cargo-build-release -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-build-release' -Target 'Build-RustRelease'
        }
        else {
            Set-AgentModeAlias -Name 'cargo-build-release' -Target 'Build-RustRelease'
        }
    }

    # ===============================================
    # Update Rust Dependencies
    # ===============================================

    <#
.SYNOPSIS
        Updates Rust project dependencies to their latest compatible versions.
    

    .DESCRIPTION
        Updates Cargo.toml dependencies to their latest versions within the
        specified version constraints. This is a convenience wrapper around
        cargo update.
    

    .PARAMETER Arguments
        Additional arguments to pass to cargo update.
        Can be used multiple times or as an array.
    

    .OUTPUTS
        System.String. Output from cargo update execution.

    .EXAMPLE
    Update-RustDependencies
        Updates all dependencies in the current project.
    

    .EXAMPLE
        Update-RustDependencies --package serde
        Updates only the serde package.
#>
    function Update-RustDependencies {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'cargo')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            Invoke-MissingToolWarning -ToolName 'rustup' -Tool 'cargo' -ToolType 'rust-package'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'rust.cargo.update' -Context @{
                has_additional_args = ($null -ne $Arguments)
            } -ScriptBlock {
                $cmdArgs = @('update')
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                & cargo @cmdArgs 2>&1
            }
        }
        else {
            try {
                $cmdArgs = @('update')
                if ($Arguments) {
                    $cmdArgs += $Arguments
                }
                $result = & cargo @cmdArgs 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run cargo update: $($_.Exception.Message)"
                return $null
            }
        }
    }

    Set-AgentModeFunction -Name 'Update-RustDependencies' -Body ${function:Update-RustDependencies}
    if (-not (Get-Alias cargo-update-deps -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-update-deps' -Target 'Update-RustDependencies'
        }
        else {
            Set-AgentModeAlias -Name 'cargo-update-deps' -Target 'Update-RustDependencies'
        }
    }

    # ===============================================
    # cargo cache - Cache cleanup
    # ===============================================

    <#
.SYNOPSIS
        Cleans up Cargo cache and build artifacts.
    

    .DESCRIPTION
        Removes cached crates and build artifacts from Cargo's cache directory.
        This helps free up disk space by removing downloaded crates and compiled artifacts.
        Uses cargo-cache if available, otherwise falls back to manual cleanup.
    

    .PARAMETER Autoclean
        Use cargo cache --autoclean to automatically clean unused cache entries.
    

    .PARAMETER All
        Remove all cache entries (use with caution).
    

    .OUTPUTS
        System.String. Output from cargo cache cleanup execution.

    .EXAMPLE
    Clear-CargoCache
        Cleans up unused cache entries automatically.
    

    .EXAMPLE
        Clear-CargoCache -Autoclean
        Uses cargo cache --autoclean for automatic cleanup.
    

    .EXAMPLE
        Clear-CargoCache -All
        Removes all cache entries (aggressive cleanup).
#>
    function Clear-CargoCache {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter()]
            [switch]$Autoclean,
            
            [Parameter()]
            [switch]$All
        )

        if (-not (Test-CachedCommand 'cargo')) {
            $repoRoot = $null
            if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                try {
                    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
                }
                catch {
                    $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
                }
            }
            else {
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
            Invoke-MissingToolWarning -ToolName 'rustup' -Tool 'cargo' -ToolType 'rust-package'
            return $null
        }

        try {
            # Check if cargo-cache is available (preferred method)
            if (Test-CachedCommand 'cargo-cache') {
                $cmdArgs = @('cache')
                if ($All) {
                    $cmdArgs += '--remove-dir', 'all'
                }
                elseif ($Autoclean) {
                    $cmdArgs += '--autoclean'
                }
                else {
                    # Default to autoclean if no specific option
                    $cmdArgs += '--autoclean'
                }
                $result = & cargo-cache @cmdArgs 2>&1
                return $result
            }
            else {
                # Fallback: use cargo's built-in cache directory cleanup
                # Cargo doesn't have a built-in cleanup command, but we can use
                # cargo cache --autoclean if cargo-cache is installed, or
                # manually clean common cache locations
                Write-Warning "cargo-cache not found. Install it with: cargo install cargo-cache"
                Write-Warning "For manual cleanup, remove files from: $env:USERPROFILE\.cargo\registry\cache (Windows) or ~/.cargo/registry/cache (Unix)"
                return $null
            }
        }
        catch {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'rust.cargo.cache-cleanup' -Context @{
                    autoclean = $Autoclean.IsPresent
                    all       = $All.IsPresent
                }
            }
            else {
                Write-Error "Failed to run cargo cache cleanup: $($_.Exception.Message)"
            }
            return $null
        }
    }

    Set-AgentModeFunction -Name 'Clear-CargoCache' -Body ${function:Clear-CargoCache}
    if (-not (Get-Alias cargo-cleanup -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-cleanup' -Target 'Clear-CargoCache'
            Set-AgentModeAlias -Name 'cargo-clean' -Target 'Clear-CargoCache'
        }
        else {
            Set-AgentModeAlias -Name 'cargo-cleanup' -Target 'Clear-CargoCache'
            Set-AgentModeAlias -Name 'cargo-clean' -Target 'Clear-CargoCache'
        }
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-rust-build'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-rust-build' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-rust-build fragment: $($_.Exception.Message)"
    }
}
