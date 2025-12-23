# ===============================================
# gem.ps1
# RubyGems package management
# ===============================================

# RubyGems aliases and functions
# Requires: gem (RubyGems - https://rubygems.org/)
# Tier: standard
# Dependencies: bootstrap, env

if (Test-CachedCommand gem) {
    # Gem outdated - check for outdated packages
    <#
    .SYNOPSIS
        Checks for outdated RubyGems packages.
    .DESCRIPTION
        Lists all installed gems that have newer versions available.
        This is equivalent to running 'gem outdated'.
    #>
    function Test-GemOutdated {
        [CmdletBinding()]
        param()
        
        & gem outdated
    }
    Set-Alias -Name gem-outdated -Value Test-GemOutdated -ErrorAction SilentlyContinue

    # Gem update packages
    <#
    .SYNOPSIS
        Updates RubyGems packages.
    .DESCRIPTION
        Updates all installed gems to their latest versions.
    #>
    function Update-GemPackages {
        [CmdletBinding()]
        param()
        
        & gem update
    }
    Set-Alias -Name gem-update -Value Update-GemPackages -ErrorAction SilentlyContinue

    # Gem self-update - update gem itself
    <#
    .SYNOPSIS
        Updates RubyGems to the latest version.
    .DESCRIPTION
        Updates RubyGems itself to the latest version using 'gem update --system'.
    #>
    function Update-GemSelf {
        [CmdletBinding()]
        param()
        
        & gem update --system
    }
    Set-Alias -Name gem-self-update -Value Update-GemSelf -ErrorAction SilentlyContinue

    # Gem install - install packages
    <#
    .SYNOPSIS
        Installs RubyGems packages.
    .DESCRIPTION
        Installs gems. Supports --user-install for local installation.
    .PARAMETER Packages
        Gem names to install.
    .PARAMETER User
        Install to user directory (--user-install).
    .PARAMETER Version
        Specific version to install (--version).
    .EXAMPLE
        Install-GemPackage rails
        Installs rails globally.
    .EXAMPLE
        Install-GemPackage rails -User
        Installs rails to user directory.
    #>
    function Install-GemPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$User,
            [string]$Version
        )
        
        $args = @()
        if ($User) {
            $args += '--user-install'
        }
        if ($Version) {
            $args += '--version', $Version
        }
        & gem install @args @Packages
    }
    Set-Alias -Name gem-install -Value Install-GemPackage -ErrorAction SilentlyContinue
    Set-Alias -Name gem-add -Value Install-GemPackage -ErrorAction SilentlyContinue

    # Gem uninstall - remove packages
    <#
    .SYNOPSIS
        Removes RubyGems packages.
    .DESCRIPTION
        Removes gems. Supports --user-install flag for user-installed gems.
    .PARAMETER Packages
        Gem names to remove.
    .PARAMETER User
        Remove from user directory (--user-install).
    .PARAMETER Version
        Specific version to remove (--version).
    .EXAMPLE
        Remove-GemPackage rails
        Removes rails from global installation.
    .EXAMPLE
        Remove-GemPackage rails -User
        Removes rails from user directory.
    #>
    function Remove-GemPackage {
        [CmdletBinding()]
        param(
            [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
            [string[]]$Packages,
            [switch]$User,
            [string]$Version
        )
        
        $args = @()
        if ($User) {
            $args += '--user-install'
        }
        if ($Version) {
            $args += '--version', $Version
        }
        & gem uninstall @args @Packages
    }
    Set-Alias -Name gem-uninstall -Value Remove-GemPackage -ErrorAction SilentlyContinue
    Set-Alias -Name gem-remove -Value Remove-GemPackage -ErrorAction SilentlyContinue

    # Ruby Installer Development Kit (ridk) - install MSYS2 development tools
    # ridk comes with Ruby when installed via Scoop on Windows
    if (Test-CachedCommand ridk) {
        <#
        .SYNOPSIS
            Installs MSYS2 development tools using Ruby Installer Development Kit.
        .DESCRIPTION
            Runs 'ridk install' to install MSYS2 development tools needed for building
            native Ruby gems on Windows. This is typically required after installing
            Ruby from Scoop to enable compilation of native extensions.
        .PARAMETER Components
            Optional components to install. If not specified, runs 'ridk install'
            which will prompt for component selection.
        .EXAMPLE
            Install-RubyDevKit
            Installs MSYS2 development tools (will prompt for component selection).
        .EXAMPLE
            Install-RubyDevKit -Components 1,2,3
            Installs specific MSYS2 components.
        .NOTES
            This command is only available on Windows when Ruby is installed via Scoop.
            After installing Ruby with 'scoop install ruby', run this command to set up
            the development environment for building native gems.
        #>
        function Install-RubyDevKit {
            [CmdletBinding()]
            param(
                [Parameter(ValueFromRemainingArguments = $true)]
                [int[]]$Components
            )
            
            if ($Components.Count -gt 0) {
                & ridk install @Components
            }
            else {
                & ridk install
            }
        }
        Set-Alias -Name ridk-install -Value Install-RubyDevKit -ErrorAction SilentlyContinue
        Set-Alias -Name ruby-devkit-install -Value Install-RubyDevKit -ErrorAction SilentlyContinue
    }
}
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'gem' -ToolType 'ruby-package' -DefaultInstallCommand 'scoop install ruby'
    }
    else {
        $hasScoop = Test-CachedCommand scoop
        if ($hasScoop) {
            'Install with: scoop install ruby'
        }
        else {
            'Install Ruby from: https://www.ruby-lang.org/ or use: scoop install ruby'
        }
    }
    Write-MissingToolWarning -Tool 'gem' -InstallHint $installHint
}
