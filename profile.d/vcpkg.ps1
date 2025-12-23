# ===============================================
# vcpkg.ps1
# vcpkg C++ package manager
# ===============================================

# vcpkg aliases and functions
# Requires: vcpkg (vcpkg - https://vcpkg.io/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand vcpkg) {
    # vcpkg install - install packages
    <#
    .SYNOPSIS
        Installs C++ libraries using vcpkg.
    .DESCRIPTION
        Installs packages from vcpkg registry. Supports --triplet and --version flags.
    .PARAMETER Packages
        Package names to install.
    .PARAMETER Triplet
        Target triplet (e.g., x64-windows, x64-linux).
    .PARAMETER Version
        Specific version to install.
    .EXAMPLE
        Install-VcpkgPackage boost
        Installs boost library.
    .EXAMPLE
        Install-VcpkgPackage boost -Triplet x64-windows
        Installs for specific platform.
    #>
    function Install-VcpkgPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Triplet,
            [string]$Version
        )
        
        foreach ($package in $Packages) {
            $args = @('install', $package)
            if ($Triplet) {
                $args += '--triplet', $Triplet
            }
            if ($Version) {
                $args += '--version', $Version
            }
            & vcpkg @args
        }
    }
    Set-Alias -Name vcpkginstall -Value Install-VcpkgPackage -ErrorAction SilentlyContinue
    Set-Alias -Name vcpkgadd -Value Install-VcpkgPackage -ErrorAction SilentlyContinue

    # vcpkg remove - remove packages
    <#
    .SYNOPSIS
        Removes C++ libraries using vcpkg.
    .DESCRIPTION
        Removes installed packages.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER Triplet
        Target triplet.
    .EXAMPLE
        Remove-VcpkgPackage boost
        Removes boost library.
    #>
    function Remove-VcpkgPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [string]$Triplet
        )
        
        foreach ($package in $Packages) {
            $args = @('remove', $package)
            if ($Triplet) {
                $args += '--triplet', $Triplet
            }
            & vcpkg @args
        }
    }
    Set-Alias -Name vcpkgremove -Value Remove-VcpkgPackage -ErrorAction SilentlyContinue
    Set-Alias -Name vcpkguninstall -Value Remove-VcpkgPackage -ErrorAction SilentlyContinue

    # vcpkg upgrade - upgrade packages
    <#
    .SYNOPSIS
        Upgrades vcpkg packages.
    .DESCRIPTION
        Upgrades specified packages or all packages if no arguments provided.
    .PARAMETER Packages
        Package names to upgrade (optional, upgrades all if omitted).
    .PARAMETER NoDryRun
        Actually perform upgrades (default is dry-run).
    .EXAMPLE
        Update-VcpkgPackages
        Shows what would be upgraded (dry-run).
    .EXAMPLE
        Update-VcpkgPackages boost -NoDryRun
        Upgrades boost package.
    #>
    function Update-VcpkgPackages {
        [CmdletBinding()]
        param(
            [Parameter(ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$NoDryRun
        )
        
        $args = @('upgrade')
        if (-not $NoDryRun) {
            $args += '--dry-run'
        }
        if ($Packages) {
            $args += $Packages
        }
        & vcpkg @args
    }
    Set-Alias -Name vcpkgupgrade -Value Update-VcpkgPackages -ErrorAction SilentlyContinue
    Set-Alias -Name vcpkgupdate -Value Update-VcpkgPackages -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'vcpkg' -InstallHint 'Install from: https://vcpkg.io/en/getting-started.html'
}
