# ===============================================
# TestLinuxPackageHelpers.ps1
# Linux system package availability testing utilities
# ===============================================

<#
.SYNOPSIS
    Checks if a Linux system package is installed via apt, pacman, or dnf.
.DESCRIPTION
    Uses the native package manager query commands to determine whether a
    package is installed. Intended for dependency checks on Linux distros.
.PARAMETER PackageName
    Distribution package name (e.g., fd-find, github-cli).
.PARAMETER PackageManager
    apt, pacman, or dnf. When omitted, auto-detects from available commands.
.EXAMPLE
    Test-LinuxSystemPackageAvailable -PackageName 'bat' -PackageManager 'pacman'
.OUTPUTS
    System.Boolean
#>
function Test-LinuxSystemPackageAvailable {
    param(
        [Parameter(Mandatory)]
        [string]$PackageName,

        [ValidateSet('apt', 'pacman', 'dnf')]
        [string]$PackageManager
    )

    if (-not $PackageManager) {
        if (Get-Command Get-SystemPackageManagerKind -ErrorAction SilentlyContinue) {
            $detected = Get-SystemPackageManagerKind
            if ($detected -in 'apt', 'pacman', 'dnf') {
                $PackageManager = $detected
            }
        }
        elseif (Get-Command pacman -ErrorAction SilentlyContinue) {
            $PackageManager = 'pacman'
        }
        elseif (Get-Command apt-get -ErrorAction SilentlyContinue) {
            $PackageManager = 'apt'
        }
        elseif (Get-Command dnf -ErrorAction SilentlyContinue) {
            $PackageManager = 'dnf'
        }
        else {
            return $false
        }
    }

    try {
        switch ($PackageManager) {
            'pacman' {
                & pacman -Q $PackageName 2>$null | Out-Null
                return ($LASTEXITCODE -eq 0)
            }
            'apt' {
                & dpkg-query -W -f='${Status}' $PackageName 2>$null | Out-Null
                if ($LASTEXITCODE -ne 0) {
                    return $false
                }
                $status = & dpkg-query -W -f='${Status}' $PackageName 2>$null
                return ($status -match 'install ok installed')
            }
            'dnf' {
                & rpm -q $PackageName 2>$null | Out-Null
                return ($LASTEXITCODE -eq 0)
            }
        }
    }
    catch {
        return $false
    }

    return $false
}
