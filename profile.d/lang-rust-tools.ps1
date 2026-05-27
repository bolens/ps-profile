# ===============================================
# lang-rust-tools.ps1
# Rust development tools (binstall, watch)
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Rust development tools (binstall, watch).

.DESCRIPTION
    Provides wrapper functions for Rust development tools:
    - Install-RustBinary: Fast binary installer via cargo-binstall
    - Watch-RustProject: Auto-rebuild on file changes via cargo-watch

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module enhances rustup.ps1, which provides basic rustup and cargo operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-rust-tools') { return }
    }

    # Import Command module for Get-ToolInstallHint (if not already available)
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
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

    Set-AgentModeFunction -Name 'Install-RustBinary' -Body ${function:Install-RustBinary}
    if (-not (Get-Alias cargo-binstall -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-binstall' -Target 'Install-RustBinary'
        }
        else {
            Set-AgentModeAlias -Name 'cargo-binstall' -Target 'Install-RustBinary'
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

    Set-AgentModeFunction -Name 'Watch-RustProject' -Body ${function:Watch-RustProject}
    if (-not (Get-Alias cargo-watch -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-watch' -Target 'Watch-RustProject'
        }
        else {
            Set-AgentModeAlias -Name 'cargo-watch' -Target 'Watch-RustProject'
        }
    }
    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-rust-tools'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-rust-tools' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-rust-tools fragment: $($_.Exception.Message)"
    }
}
