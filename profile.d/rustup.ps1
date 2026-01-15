# ===============================================
# rustup.ps1
# Rustup toolchain helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    Rustup toolchain helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Rustup operations.
    Functions check for rustup availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Rustup
    Author: PowerShell Profile
#>

# Rustup execute - run rustup with arguments
<#
.SYNOPSIS
    Executes Rustup commands.

.DESCRIPTION
    Wrapper function for Rustup CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to rustup.

.EXAMPLE
    Invoke-Rustup --version

.EXAMPLE
    Invoke-Rustup show
#>
function Invoke-Rustup {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand rustup) {
        & rustup
    }
    else {
        Write-MissingToolWarning -Tool 'rustup' -InstallHint 'Install with: scoop install rustup'
    }
}

# Rustup update - update Rust toolchain
<#
.SYNOPSIS
    Updates the Rust toolchain.

.DESCRIPTION
    Wrapper for rustup update command.

.EXAMPLE
    Update-RustupToolchain
#>
function Update-RustupToolchain {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand rustup) {
        & rustup update
    }
    else {
        Write-MissingToolWarning -Tool 'rustup' -InstallHint 'Install with: scoop install rustup'
    }
}

# Rustup install - install Rust toolchains
<#
.SYNOPSIS
    Installs Rust toolchains.

.DESCRIPTION
    Wrapper for rustup install command.

.PARAMETER Arguments
    Arguments to pass to rustup install.

.EXAMPLE
    Install-RustupToolchain stable

.EXAMPLE
    Install-RustupToolchain nightly
#>
function Install-RustupToolchain {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand rustup) {
        & rustup install @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'rustup' -InstallHint 'Install with: scoop install rustup'
    }
}

# Rustup check - check for updates
<#
.SYNOPSIS
    Checks for Rust toolchain updates.

.DESCRIPTION
    Checks for available updates to the Rust toolchain without installing them.
    This is equivalent to running 'rustup check'.

.EXAMPLE
    Test-RustupUpdates
    Checks for available Rust toolchain updates.
#>
function Test-RustupUpdates {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand rustup) {
        & rustup check
    }
    else {
        Write-MissingToolWarning -Tool 'rustup' -InstallHint 'Install with: scoop install rustup'
    }
}

# Cargo add - add dependencies to Cargo project
<#
.SYNOPSIS
    Adds dependencies to Cargo project.
.DESCRIPTION
    Adds packages to Cargo.toml. Supports --dev flag for dev dependencies.
.PARAMETER Packages
    Package names to add.
.PARAMETER Dev
    Add as dev dependency (--dev).
.PARAMETER Build
    Add as build dependency (--build).
.PARAMETER Version
    Specific version to add (--version).
.EXAMPLE
    Add-CargoDependency serde
    Adds serde as a production dependency.
.EXAMPLE
    Add-CargoDependency tokio-test -Dev
    Adds tokio-test as a dev dependency.
#>
function Add-CargoDependency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
        [string[]]$Packages,
        [switch]$Dev,
        [switch]$Build,
        [string]$Version
    )
    
    if (Test-CachedCommand cargo) {
        $args = @()
        if ($Dev) {
            $args += '--dev'
        }
        if ($Build) {
            $args += '--build'
        }
        if ($Version) {
            $args += '--version', $Version
        }
        & cargo add @args @Packages
    }
    else {
        Write-MissingToolWarning -Tool 'cargo' -InstallHint 'Install Rust toolchain with: scoop install rustup'
    }
}

# Cargo remove - remove dependencies from Cargo project
<#
.SYNOPSIS
    Removes dependencies from Cargo project.
.DESCRIPTION
    Removes packages from Cargo.toml. Supports --dev flag.
.PARAMETER Packages
    Package names to remove.
.PARAMETER Dev
    Remove from dev dependencies (--dev).
.PARAMETER Build
    Remove from build dependencies (--build).
.EXAMPLE
    Remove-CargoDependency serde
    Removes serde from production dependencies.
.EXAMPLE
    Remove-CargoDependency tokio-test -Dev
    Removes tokio-test from dev dependencies.
#>
function Remove-CargoDependency {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
        [string[]]$Packages,
        [switch]$Dev,
        [switch]$Build
    )
    
    if (Test-CachedCommand cargo) {
        $args = @()
        if ($Dev) {
            $args += '--dev'
        }
        if ($Build) {
            $args += '--build'
        }
        & cargo remove @args @Packages
    }
    else {
        Write-MissingToolWarning -Tool 'cargo' -InstallHint 'Install Rust toolchain with: scoop install rustup'
    }
}

# Cargo install - install packages globally
<#
.SYNOPSIS
    Installs Cargo packages globally.
.DESCRIPTION
    Installs packages as global binaries using cargo install.
.PARAMETER Packages
    Package names to install.
.PARAMETER Version
    Specific version to install (--version).
.EXAMPLE
    Install-CargoPackage cargo-watch
    Installs cargo-watch globally.
#>
function Install-CargoPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
        [string[]]$Packages,
        [string]$Version
    )
    
    if (Test-CachedCommand cargo) {
        foreach ($package in $Packages) {
            $args = @('install', $package)
            if ($Version) {
                $args += '--version', $Version
            }
            & cargo @args
        }
    }
    else {
        Write-MissingToolWarning -Tool 'cargo' -InstallHint 'Install Rust toolchain with: scoop install rustup'
    }
}

# Cargo uninstall - remove global packages
<#
.SYNOPSIS
    Removes globally installed Cargo packages.
.DESCRIPTION
    Removes packages installed with cargo install.
.PARAMETER Packages
    Package names to remove.
.EXAMPLE
    Remove-CargoPackage cargo-watch
    Removes cargo-watch from global installation.
#>
function Remove-CargoPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
        [string[]]$Packages
    )
    
    if (Test-CachedCommand cargo) {
        & cargo uninstall @Packages
    }
    else {
        Write-MissingToolWarning -Tool 'cargo' -InstallHint 'Install Rust toolchain with: scoop install rustup'
    }
}

# Cargo install-update - update all cargo packages
<#
.SYNOPSIS
    Updates all installed cargo packages to their latest versions.

.DESCRIPTION
    Updates all globally installed cargo packages using cargo-install-update.
    This is equivalent to running 'cargo install-update --all'.
    Requires the cargo-install-update crate to be installed.

.EXAMPLE
    Update-CargoPackages
    Updates all globally installed cargo packages.
#>
function Update-CargoPackages {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand cargo) {
        & cargo install-update --all
    }
    else {
        Write-MissingToolWarning -Tool 'cargo' -InstallHint 'Install Rust toolchain with: scoop install rustup'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'rustup' -Target 'Invoke-Rustup'
    Set-AgentModeAlias -Name 'rustup-update' -Target 'Update-RustupToolchain'
    Set-AgentModeAlias -Name 'rustup-install' -Target 'Install-RustupToolchain'
    Set-AgentModeAlias -Name 'rustup-check' -Target 'Test-RustupUpdates'
    Set-AgentModeAlias -Name 'cargo-update' -Target 'Update-CargoPackages'
}
else {
    Set-Alias -Name 'rustup' -Value 'Invoke-Rustup' -ErrorAction SilentlyContinue
    Set-Alias -Name 'rustup-update' -Value 'Update-RustupToolchain' -ErrorAction SilentlyContinue
    Set-Alias -Name 'rustup-install' -Value 'Install-RustupToolchain' -ErrorAction SilentlyContinue
    Set-Alias -Name 'rustup-check' -Value 'Test-RustupUpdates' -ErrorAction SilentlyContinue
    Set-Alias -Name 'cargo-update' -Value 'Update-CargoPackages' -ErrorAction SilentlyContinue
}
