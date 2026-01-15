# ===============================================
# pip.ps1
# PIP Python Package Manager Helpers
# ===============================================
# Provides convenient aliases and wrapper functions for pip package manager operations.
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand pip) {
    # PIP install - install packages
    <#
    .SYNOPSIS
        Installs Python packages using pip.
    .DESCRIPTION
        Installs packages. Supports --user (local) and --global (default) installation.
    .PARAMETER Packages
        Package names to install.
    .PARAMETER User
        Install to user site-packages (--user).
    .PARAMETER Global
        Install globally (default).
    .EXAMPLE
        Install-PipPackage requests
        Installs requests globally.
    .EXAMPLE
        Install-PipPackage requests -User
        Installs requests to user directory.
    #>
    function Install-PipPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$User,
            [switch]$Global
        )
        
        if (Test-CachedCommand pip) {
            $args = @()
            if ($User) {
                $args += '--user'
            }
            & pip install @args @Packages
        }
        else {
            Write-MissingToolWarning -Tool 'pip' -InstallHint 'Install with: python -m ensurepip --upgrade'
        }
    }
    Set-Alias -Name pipinstall -Value Install-PipPackage -ErrorAction SilentlyContinue
    Set-Alias -Name pipadd -Value Install-PipPackage -ErrorAction SilentlyContinue

    # PIP uninstall - remove packages
    <#
    .SYNOPSIS
        Removes Python packages using pip.
    .DESCRIPTION
        Removes packages. Supports --user flag for user-installed packages.
    .PARAMETER Packages
        Package names to remove.
    .PARAMETER User
        Remove from user site-packages (--user).
    .EXAMPLE
        Remove-PipPackage requests
        Removes requests from global installation.
    .EXAMPLE
        Remove-PipPackage requests -User
        Removes requests from user directory.
    #>
    function Remove-PipPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$User
        )
        
        if (Test-CachedCommand pip) {
            $args = @()
            if ($User) {
                $args += '--user'
            }
            & pip uninstall @args @Packages
        }
        else {
            Write-MissingToolWarning -Tool 'pip' -InstallHint 'Install with: python -m ensurepip --upgrade'
        }
    }
    Set-Alias -Name pipuninstall -Value Remove-PipPackage -ErrorAction SilentlyContinue
    Set-Alias -Name pipremove -Value Remove-PipPackage -ErrorAction SilentlyContinue

    # PIP outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated Python packages.
    .DESCRIPTION
        Lists all packages that have newer versions available.
        This is equivalent to running 'pip list --outdated'.
    #>
    function Test-PipOutdated {
        [CmdletBinding()]
        param()
        
        if (Test-CachedCommand pip) {
            & pip list --outdated
        }
        else {
            Write-MissingToolWarning -Tool 'pip' -InstallHint 'Install with: python -m ensurepip --upgrade'
        }
    }
    Set-Alias -Name pipoutdated -Value Test-PipOutdated -ErrorAction SilentlyContinue

    # PIP update - update all packages
    <#
    .SYNOPSIS
        Updates all Python packages to their latest versions.
    .DESCRIPTION
        Lists outdated packages and upgrades them to their latest versions.
        This is equivalent to running 'pip list --outdated' followed by
        'pip install --upgrade' for each package.
    #>
    function Update-PipPackages {
        [CmdletBinding()]
        param()
        
        if (Test-CachedCommand pip) {
            Write-Verbose "Checking for outdated packages..."
            & pip list --outdated
            
            Write-Verbose "Upgrading all packages..."
            $packages = & pip freeze | ForEach-Object { $_.Split('==')[0] }
            if ($packages) {
                foreach ($package in $packages) {
                    Write-Verbose "Upgrading $package..."
                    & pip install --upgrade $package
                }
            }
            else {
                Write-Output "No packages found to upgrade."
            }
        }
        else {
            Write-MissingToolWarning -Tool 'pip' -InstallHint 'Install with: python -m ensurepip --upgrade'
        }
    }
    Set-Alias -Name pipupdate -Value Update-PipPackages -ErrorAction SilentlyContinue

    # PIP self-update - update pip itself
    <#
    .SYNOPSIS
        Updates pip to the latest version.
    .DESCRIPTION
        Updates pip itself to the latest version using 'pip install --upgrade pip'.
    #>
    function Update-PipSelf {
        [CmdletBinding()]
        param()
        
        if (Test-CachedCommand pip) {
            & pip install --upgrade pip
        }
        else {
            Write-MissingToolWarning -Tool 'pip' -InstallHint 'Install with: python -m ensurepip --upgrade'
        }
    }
    Set-Alias -Name pipupgrade -Value Update-PipSelf -ErrorAction SilentlyContinue

    # PIP freeze - backup installed packages
    <#
    .SYNOPSIS
        Exports installed pip packages to a requirements.txt file.
    .DESCRIPTION
        Creates a requirements.txt file containing all installed pip packages with versions.
        This file can be used to restore packages on another system or after a reinstall.
    .PARAMETER Path
        Path to save the export file. Defaults to "requirements.txt" in current directory.
    .PARAMETER User
        Export only user-installed packages (--user flag).
    .EXAMPLE
        Export-PipPackages
        Exports packages to requirements.txt in current directory.
    .EXAMPLE
        Export-PipPackages -Path "C:\backup\pip-requirements.txt"
        Exports packages to a specific file.
    .EXAMPLE
        Export-PipPackages -User
        Exports only user-installed packages.
    #>
    function Export-PipPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'requirements.txt',
            [switch]$User
        )
        
        if (Test-CachedCommand pip) {
            $args = @('freeze')
            if ($User) {
                $args += '--user'
            }
            & pip @args | Out-File -FilePath $Path -Encoding UTF8
        }
        else {
            Write-MissingToolWarning -Tool 'pip' -InstallHint 'Install with: python -m ensurepip --upgrade'
        }
    }
    Set-Alias -Name pipexport -Value Export-PipPackages -ErrorAction SilentlyContinue
    Set-Alias -Name pipbackup -Value Export-PipPackages -ErrorAction SilentlyContinue

    # PIP install from requirements - restore packages
    <#
    .SYNOPSIS
        Restores pip packages from a requirements.txt file.
    .DESCRIPTION
        Installs all packages listed in a requirements.txt file.
        This is useful for restoring packages after a system reinstall or on a new machine.
    .PARAMETER Path
        Path to the requirements.txt file to import. Defaults to "requirements.txt" in current directory.
    .PARAMETER User
        Install to user site-packages (--user flag).
    .EXAMPLE
        Import-PipPackages
        Restores packages from requirements.txt in current directory.
    .EXAMPLE
        Import-PipPackages -Path "C:\backup\pip-requirements.txt"
        Restores packages from a specific file.
    .EXAMPLE
        Import-PipPackages -User
        Restores packages to user directory.
    #>
    function Import-PipPackages {
        [CmdletBinding()]
        param(
            [string]$Path = 'requirements.txt',
            [switch]$User
        )
        
        if (-not (Test-Path -LiteralPath $Path)) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord (New-Object System.Management.Automation.ErrorRecord(
                        [System.IO.FileNotFoundException]::new("Requirements file not found: $Path"),
                        'RequirementsFileNotFound',
                        [System.Management.Automation.ErrorCategory]::ObjectNotFound,
                        $Path
                    )) -OperationName 'pip.packages.import' -Context @{ path = $Path }
            }
            else {
                Write-Error "Requirements file not found: $Path"
            }
            return
        }
        
        if (Test-CachedCommand pip) {
            if (Get-Command Invoke-WithWideEvent -ErrorAction SilentlyContinue) {
                Invoke-WithWideEvent -OperationName 'pip.packages.import' -Context @{
                    path = $Path
                    user = $User.IsPresent
                } -ScriptBlock {
                    $args = @('install', '-r', $Path)
                    if ($User) {
                        $args += '--user'
                    }
                    & pip @args
                } | Out-Null
            }
            else {
                $args = @('install', '-r', $Path)
                if ($User) {
                    $args += '--user'
                }
                & pip @args
            }
        }
        else {
            Write-MissingToolWarning -Tool 'pip' -InstallHint 'Install with: python -m ensurepip --upgrade'
        }
    }
    Set-Alias -Name pipimport -Value Import-PipPackages -ErrorAction SilentlyContinue
    Set-Alias -Name piprestore -Value Import-PipPackages -ErrorAction SilentlyContinue
}
else {
    Write-MissingToolWarning -Tool 'pip' -InstallHint 'Install with: python -m ensurepip --upgrade'
}
