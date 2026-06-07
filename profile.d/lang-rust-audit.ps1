# ===============================================
# lang-rust-audit.ps1
# Rust dependency security and quality auditing
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Rust dependency security and quality auditing.

.DESCRIPTION
    Provides wrapper functions for Rust development tools:
    - Audit-RustProject: Security audit via cargo-audit
    - Test-RustOutdated: Check for outdated dependencies via cargo-outdated

.NOTES
    All functions gracefully degrade when tools are not installed.
    This module enhances rustup.ps1, which provides basic rustup and cargo operations.
#>

try {
    # Idempotency check: skip if already loaded
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'lang-rust-audit') { return }
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

        $cargoAuditCmd = if (Test-CachedCommand 'cargo-audit') { Get-CachedExternalCommand 'cargo-audit' } else { $null }
        if (-not $cargoAuditCmd) {
            Invoke-MissingToolWarning -ToolName 'cargo-audit' -ToolType 'rust-package'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'rust.cargo-audit.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & $cargoAuditCmd $Arguments 2>&1
            }
        }
        else {
            try {
                $result = & $cargoAuditCmd $Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run cargo-audit: $($_.Exception.Message)"
                return $null
            }
        }
    }

    Set-AgentModeFunction -Name 'Audit-RustProject' -Body ${function:Audit-RustProject}
    if (-not (Get-Alias cargo-audit -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-audit' -Target 'Audit-RustProject'
        }
        else {
            Set-AgentModeAlias -Name 'cargo-audit' -Target 'Audit-RustProject'
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

        $cargoOutdatedCmd = if (Test-CachedCommand 'cargo-outdated') { Get-CachedExternalCommand 'cargo-outdated' } else { $null }
        if (-not $cargoOutdatedCmd) {
            Invoke-MissingToolWarning -ToolName 'cargo-outdated' -ToolType 'rust-package'
            return $null
        }

        if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
            return Invoke-WithWideEvent -OperationName 'rust.cargo-outdated.invoke' -Context @{
                arguments = $Arguments
            } -ScriptBlock {
                & $cargoOutdatedCmd $Arguments 2>&1
            }
        }
        else {
            try {
                $result = & $cargoOutdatedCmd $Arguments 2>&1
                return $result
            }
            catch {
                Write-Error "Failed to run cargo-outdated: $($_.Exception.Message)"
                return $null
            }
        }
    }

    Set-AgentModeFunction -Name 'Test-RustOutdated' -Body ${function:Test-RustOutdated}
    if (-not (Get-Alias cargo-outdated -ErrorAction SilentlyContinue)) {
        if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
            Set-AgentModeAlias -Name 'cargo-outdated' -Target 'Test-RustOutdated'
        }
        else {
            Set-AgentModeAlias -Name 'cargo-outdated' -Target 'Test-RustOutdated'
        }
    }
    # Mark fragment as loaded
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'lang-rust-audit'
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -FragmentName 'lang-rust-audit' -ErrorRecord $_
    }
    else {
        Write-Error "Failed to load lang-rust-audit fragment: $($_.Exception.Message)"
    }
}
