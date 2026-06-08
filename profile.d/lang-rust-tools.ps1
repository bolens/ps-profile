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
    

    .OUTPUTS
        System.String. Output from cargo-binstall execution.

    .EXAMPLE
        Install-RustBinary cargo-watch
        Installs cargo-watch using cargo-binstall.
    

    .EXAMPLE
        Install-RustBinary cargo-audit --version 0.18.0
        Installs a specific version of cargo-audit.
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

        $cargoBinstallCmd = if (Test-CachedCommand 'cargo-binstall') { Get-CachedExternalCommand 'cargo-binstall' } else { $null }
        if (-not $cargoBinstallCmd) {
            Invoke-MissingToolWarning -ToolName 'cargo-binstall' -ToolType 'rust-package'
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
                & $cargoBinstallCmd @cmdArgs 2>&1
            }
        }
        else {
            try {
                $cmdArgs = @()
                if ($Version) {
                    $cmdArgs += '--version', $Version
                }
                $cmdArgs += $Packages
                $result = & $cargoBinstallCmd @cmdArgs 2>&1
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
    

    .OUTPUTS
        System.String. Output from cargo-watch execution.

    .EXAMPLE
    Watch-RustProject -Command 'pwsh -NoProfile -File scripts/test.ps1'
        Watches for changes and runs 'cargo check'.
    

    .EXAMPLE
        Watch-RustProject -Command test
        Watches for changes and runs 'cargo test'.
    

    .EXAMPLE
        Watch-RustProject -Command run -- --release
        Watches for changes and runs 'cargo run --release'.
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

        $cargoWatchCmd = if (Test-CachedCommand 'cargo-watch') { Get-CachedExternalCommand 'cargo-watch' } else { $null }
        if (-not $cargoWatchCmd) {
            Invoke-MissingToolWarning -ToolName 'cargo-watch' -ToolType 'rust-package'
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
                & $cargoWatchCmd @cmdArgs 2>&1
            }
        }
        else {
            try {
                $cmdArgs = @('-x', "cargo $Command")
                if ($Arguments) {
                    $cmdArgs += '--'
                    $cmdArgs += $Arguments
                }
                $result = & $cargoWatchCmd @cmdArgs 2>&1
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
