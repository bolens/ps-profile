# ===============================================
# lang-rust.ps1
# Rust development tools (enhanced)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Rust development tools fragment for enhanced Rust development workflows.

.DESCRIPTION
    Provides wrapper functions for Rust development tools that enhance the basic
    rustup.ps1 functionality:
    - cargo-binstall: Fast binary installer for Rust tools
    - cargo-watch: File watcher for Rust projects
    - cargo-audit: Security audit for Rust dependencies
    - cargo-outdated: Check for outdated dependencies
    - cargo build: Build release binaries with optimizations

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module enhances rustup.ps1, which provides basic rustup and cargo operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-rust') { return }
    }
    
    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = $null
        if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            try {
                $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction Stop
            }
            catch {
                # Get-RepoRoot expects scripts/ subdirectory, but we're in profile.d/
                # Fall back to manual path resolution
                $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
            }
        }
        else {
            $repoRoot = Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }
        
        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # ===============================================
    # cargo-binstall - Fast binary installer
    # ===============================================

    <#
    .SYNOPSIS
        Installs Rust binaries using cargo-binstall.
    
    .DESCRIPTION
        Wrapper function for cargo-binstall, a fast binary installer for Rust tools.
        cargo-binstall downloads pre-built binaries instead of compiling from source,
        making installation much faster than cargo install.
    
    .PARAMETER Packages
        Package names to install.
        Can be used multiple times or as an array.
    
    .PARAMETER Version
        Specific version to install (--version).
    
    .EXAMPLE
        Install-RustBinary cargo-watch
        Installs cargo-watch using cargo-binstall.
    
    .EXAMPLE
        Install-RustBinary cargo-audit --version 0.18.0
        Installs a specific version of cargo-audit.
    
    .OUTPUTS
        System.String. Output from cargo-binstall execution.
    #>
    function Install-RustBinary {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            
            [Parameter()]
            [string]$Version
        )

        if (-not (Test-CachedCommand 'cargo-binstall')) {
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
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'cargo-binstall' -ToolType 'rust-package'
            }
            elseif (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'cargo-binstall' -RepoRoot $repoRoot
            }
            else {
                "Install with: cargo install cargo-binstall (or scoop install cargo-binstall)"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'cargo-binstall' -InstallHint $installHint
            }
            else {
                Write-Warning "cargo-binstall not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'rust.cargo-binstall.invoke' -Context @{
                packages = $Packages
                version  = $Version
            } -ScriptBlock {
                $cmdArgs = @()
                if ($Version) {
                    $cmdArgs += '--version', $Version
                }
                $cmdArgs += $Packages
                & cargo-binstall @cmdArgs 2>&1
            }
        }
        else {
            try {
                $cmdArgs = @()
                if ($Version) {
                    $cmdArgs += '--version', $Version
                }
                $cmdArgs += $Packages
                $result = & cargo-binstall @cmdArgs 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run cargo-binstall: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Install-RustBinary -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Install-RustBinary' -Body ${function:Install-RustBinary}
    }
    if (-not (Get-Alias cargo-binstall -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-binstall' -Target 'Install-RustBinary'
        }
        else {
            Set-Alias -Name 'cargo-binstall' -Value 'Install-RustBinary' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # cargo-watch - File watcher
    # ===============================================

    <#
    .SYNOPSIS
        Watches files and runs cargo commands on changes.
    
    .DESCRIPTION
        Wrapper function for cargo-watch, a file watcher that automatically runs
        cargo commands when files change. Useful for continuous testing and building.
    
    .PARAMETER Command
        Cargo command to run (e.g., 'test', 'build', 'run').
        Defaults to 'check' if not specified.
    
    .PARAMETER Arguments
        Additional arguments to pass to cargo-watch.
        Can be used multiple times or as an array.
    
    .EXAMPLE
        Watch-RustProject
        Watches for changes and runs 'cargo check'.
    
    .EXAMPLE
        Watch-RustProject -Command test
        Watches for changes and runs 'cargo test'.
    
    .EXAMPLE
        Watch-RustProject -Command run -- --release
        Watches for changes and runs 'cargo run --release'.
    
    .OUTPUTS
        System.String. Output from cargo-watch execution.
    #>
    function Watch-RustProject {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter()]
            [string]$Command = 'check',
            
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'cargo-watch')) {
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
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'cargo-watch' -ToolType 'rust-package'
            }
            elseif (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'cargo-watch' -RepoRoot $repoRoot
            }
            else {
                "Install with: cargo install cargo-watch (or cargo-binstall cargo-watch)"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'cargo-watch' -InstallHint $installHint
            }
            else {
                Write-Warning "cargo-watch not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'rust.cargo-watch.invoke' -Context @{
                command             = $Command
                has_additional_args = ($null -ne $Arguments)
            } -ScriptBlock {
                $cmdArgs = @('-x', "cargo $Command")
                if ($Arguments) {
                    $cmdArgs += '--'
                    $cmdArgs += $Arguments
                }
                & cargo-watch @cmdArgs 2>&1
            }
        }
        else {
            try {
                $cmdArgs = @('-x', "cargo $Command")
                if ($Arguments) {
                    $cmdArgs += '--'
                    $cmdArgs += $Arguments
                }
                $result = & cargo-watch @cmdArgs 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run cargo-watch: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Watch-RustProject -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Watch-RustProject' -Body ${function:Watch-RustProject}
    }
    if (-not (Get-Alias cargo-watch -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-watch' -Target 'Watch-RustProject'
        }
        else {
            Set-Alias -Name 'cargo-watch' -Value 'Watch-RustProject' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # cargo-audit - Security audit
    # ===============================================

    <#
    .SYNOPSIS
        Audits Rust project dependencies for security vulnerabilities.
    
    .DESCRIPTION
        Wrapper function for cargo-audit, which checks Rust dependencies against
        the RustSec advisory database for known security vulnerabilities.
    
    .PARAMETER Arguments
        Additional arguments to pass to cargo-audit.
        Can be used multiple times or as an array.
    
    .EXAMPLE
        Audit-RustProject
        Audits the current Rust project for security vulnerabilities.
    
    .EXAMPLE
        Audit-RustProject --deny warnings
        Audits and treats warnings as errors.
    
    .OUTPUTS
        System.String. Output from cargo-audit execution.
    #>
    function Audit-RustProject {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'cargo-audit')) {
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
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'cargo-audit' -ToolType 'rust-package'
            }
            elseif (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'cargo-audit' -RepoRoot $repoRoot
            }
            else {
                "Install with: cargo install cargo-audit (or cargo-binstall cargo-audit)"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'cargo-audit' -InstallHint $installHint
            }
            else {
                Write-Warning "cargo-audit not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'rust.cargo-audit.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & cargo-audit $Arguments 2>&1
            }
        }
        else {
            try {
                $result = & cargo-audit $Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run cargo-audit: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Audit-RustProject -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Audit-RustProject' -Body ${function:Audit-RustProject}
    }
    if (-not (Get-Alias cargo-audit -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-audit' -Target 'Audit-RustProject'
        }
        else {
            Set-Alias -Name 'cargo-audit' -Value 'Audit-RustProject' -ErrorAction SilentlyContinue
        }
    }

    # ===============================================
    # cargo-outdated - Dependency updates
    # ===============================================

    <#
    .SYNOPSIS
        Checks for outdated Rust dependencies.
    
    .DESCRIPTION
        Wrapper function for cargo-outdated, which checks Rust project dependencies
        for available updates and displays version information.
    
    .PARAMETER Arguments
        Additional arguments to pass to cargo-outdated.
        Can be used multiple times or as an array.
    
    .EXAMPLE
        Test-RustOutdated
        Checks for outdated dependencies in the current project.
    
    .EXAMPLE
        Test-RustOutdated --aggressive
        Checks for more aggressive updates including minor version bumps.
    
    .OUTPUTS
        System.String. Output from cargo-outdated execution.
    #>
    function Test-RustOutdated {
        [CmdletBinding()]
        [OutputType([string])]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Arguments
        )

        if (-not (Test-CachedCommand 'cargo-outdated')) {
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
            $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
                Get-PreferenceAwareInstallHint -ToolName 'cargo-outdated' -ToolType 'rust-package'
            }
            elseif (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'cargo-outdated' -RepoRoot $repoRoot
            }
            else {
                "Install with: cargo install cargo-outdated (or cargo-binstall cargo-outdated)"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'cargo-outdated' -InstallHint $installHint
            }
            else {
                Write-Warning "cargo-outdated not found. $installHint"
            }
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'rust.cargo-outdated.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & cargo-outdated $Arguments 2>&1
            }
        }
        else {
            try {
                $result = & cargo-outdated $Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run cargo-outdated: $($_.Exception.Message)"
                return $null
            }
        }
    }

    if (-not (Test-Path Function:\Test-RustOutdated -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Test-RustOutdated' -Body ${function:Test-RustOutdated}
    }
    if (-not (Get-Alias cargo-outdated -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-outdated' -Target 'Test-RustOutdated'
        }
        else {
            Set-Alias -Name 'cargo-outdated' -Value 'Test-RustOutdated' -ErrorAction SilentlyContinue
        }
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
    
    .EXAMPLE
        Build-RustRelease
        Builds the current project in release mode.
    
    .EXAMPLE
        Build-RustRelease --bin myapp
        Builds a specific binary in release mode.
    
    .OUTPUTS
        System.String. Output from cargo build execution.
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
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'cargo' -RepoRoot $repoRoot
            }
            else {
                "Install Rust toolchain with: scoop install rustup"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'cargo' -InstallHint $installHint
            }
            else {
                Write-Warning "cargo not found. $installHint"
            }
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

    if (-not (Test-Path Function:\Build-RustRelease -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Build-RustRelease' -Body ${function:Build-RustRelease}
    }
    if (-not (Get-Alias cargo-build-release -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-build-release' -Target 'Build-RustRelease'
        }
        else {
            Set-Alias -Name 'cargo-build-release' -Value 'Build-RustRelease' -ErrorAction SilentlyContinue
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
    
    .EXAMPLE
        Update-RustDependencies
        Updates all dependencies in the current project.
    
    .EXAMPLE
        Update-RustDependencies --package serde
        Updates only the serde package.
    
    .OUTPUTS
        System.String. Output from cargo update execution.
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
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'cargo' -RepoRoot $repoRoot
            }
            else {
                "Install Rust toolchain with: scoop install rustup"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'cargo' -InstallHint $installHint
            }
            else {
                Write-Warning "cargo not found. $installHint"
            }
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

    if (-not (Test-Path Function:\Update-RustDependencies -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Update-RustDependencies' -Body ${function:Update-RustDependencies}
    }
    if (-not (Get-Alias cargo-update-deps -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-update-deps' -Target 'Update-RustDependencies'
        }
        else {
            Set-Alias -Name 'cargo-update-deps' -Value 'Update-RustDependencies' -ErrorAction SilentlyContinue
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
    
    .EXAMPLE
        Clear-CargoCache
        Cleans up unused cache entries automatically.
    
    .EXAMPLE
        Clear-CargoCache -Autoclean
        Uses cargo cache --autoclean for automatic cleanup.
    
    .EXAMPLE
        Clear-CargoCache -All
        Removes all cache entries (aggressive cleanup).
    
    .OUTPUTS
        System.String. Output from cargo cache cleanup execution.
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
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                Get-ToolInstallHint -ToolName 'cargo' -RepoRoot $repoRoot
            }
            else {
                "Install Rust toolchain with: scoop install rustup"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'cargo' -InstallHint $installHint
            }
            else {
                Write-Warning "cargo not found. $installHint"
            }
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

    if (-not (Test-Path Function:\Clear-CargoCache -ErrorAction SilentlyContinue)) {
        Set-AgentModeFunction -Name 'Clear-CargoCache' -Body ${function:Clear-CargoCache}
    }
    if (-not (Get-Alias cargo-cleanup -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-cleanup' -Target 'Clear-CargoCache'
            Set-AgentModeAlias -Name 'cargo-clean' -Target 'Clear-CargoCache'
        }
        else {
            Set-Alias -Name 'cargo-cleanup' -Value 'Clear-CargoCache' -ErrorAction SilentlyContinue
            Set-Alias -Name 'cargo-clean' -Value 'Clear-CargoCache' -ErrorAction SilentlyContinue
        }
    }

    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-rust'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-rust' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-rust fragment: $($_.Exception.Message)"
    }
}
