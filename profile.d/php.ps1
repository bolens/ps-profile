# ===============================================
# php.ps1
# PHP development helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env

<#
.SYNOPSIS
    PHP development helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common PHP operations.
    Functions check for php/composer availability using Test-HasCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Php
    Author: PowerShell Profile
#>

# PHP execute - run php with arguments
<#
.SYNOPSIS
    Executes PHP commands.

.DESCRIPTION
    Wrapper function for PHP CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to php.

.EXAMPLE
    Invoke-Php --version

.EXAMPLE
    Invoke-Php script.php
#>
function Invoke-Php {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand php) {
        & php @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'php' -ToolType 'php-package' -DefaultInstallCommand 'scoop install php'
        }
        else {
            'Install with: scoop install php'
        }
        Write-MissingToolWarning -Tool 'php' -InstallHint $installHint
    }
}

# PHP built-in server - start development server
<#
.SYNOPSIS
    Starts PHP built-in development server.

.DESCRIPTION
    Wrapper for PHP built-in server command.

.PARAMETER Port
    Port number for the server (default: 8000).

.EXAMPLE
    Start-PhpServer

.EXAMPLE
    Start-PhpServer -Port 3000
#>
function Start-PhpServer {
    [CmdletBinding()]
    param(
        [Parameter(Position = 0)]
        [int]$Port = 8000
    )
    
    if (Test-CachedCommand php) {
        php -S localhost:$Port
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'php' -ToolType 'php-package' -DefaultInstallCommand 'scoop install php'
        }
        else {
            'Install with: scoop install php'
        }
        Write-MissingToolWarning -Tool 'php' -InstallHint $installHint
    }
}

# Composer - PHP dependency manager
<#
.SYNOPSIS
    Executes Composer commands.

.DESCRIPTION
    Wrapper function for Composer that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to composer.

.EXAMPLE
    Invoke-Composer --version

.EXAMPLE
    Invoke-Composer install
#>
function Invoke-Composer {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand composer) {
        composer @Arguments
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'composer' -ToolType 'php-package' -DefaultInstallCommand 'scoop install composer'
        }
        else {
            'Install with: scoop install composer'
        }
        Write-MissingToolWarning -Tool 'composer' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'php' -Target 'Invoke-Php'
    Set-AgentModeAlias -Name 'php-server' -Target 'Start-PhpServer'
    Set-AgentModeAlias -Name 'composer' -Target 'Invoke-Composer'
}
else {
    Set-Alias -Name 'php' -Value 'Invoke-Php' -ErrorAction SilentlyContinue
    Set-Alias -Name 'php-server' -Value 'Start-PhpServer' -ErrorAction SilentlyContinue
    Set-Alias -Name 'composer' -Value 'Invoke-Composer' -ErrorAction SilentlyContinue
}
function Test-ComposerOutdated {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand composer) {
        & composer outdated
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'composer' -ToolType 'php-package' -DefaultInstallCommand 'scoop install composer'
        }
        else {
            'Install with: scoop install composer'
        }
        Write-MissingToolWarning -Tool 'composer' -InstallHint $installHint
    }
}

# Composer update - update all packages
<#
.SYNOPSIS
    Updates all packages in the current Composer project to their latest versions.
.DESCRIPTION
    Updates all packages to their latest versions according to the version constraints
    specified in composer.json. This is equivalent to running 'composer update'.
.EXAMPLE
    Update-ComposerPackages
    Updates all packages in the current Composer project.
#>
function Update-ComposerPackages {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand composer) {
        & composer update
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'composer' -ToolType 'php-package' -DefaultInstallCommand 'scoop install composer'
        }
        else {
            'Install with: scoop install composer'
        }
        Write-MissingToolWarning -Tool 'composer' -InstallHint $installHint
    }
}

# Composer self-update - update Composer itself
<#
.SYNOPSIS
    Updates Composer to the latest version.
.DESCRIPTION
    Updates Composer itself to the latest version using 'composer self-update'.
.EXAMPLE
    Update-ComposerSelf
    Updates Composer to the latest version.
#>
function Update-ComposerSelf {
    [CmdletBinding()]
    param()
    
    if (Test-CachedCommand composer) {
        & composer self-update
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'composer' -ToolType 'php-package' -DefaultInstallCommand 'scoop install composer'
        }
        else {
            'Install with: scoop install composer'
        }
        Write-MissingToolWarning -Tool 'composer' -InstallHint $installHint
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'php' -Target 'Invoke-Php'
    Set-AgentModeAlias -Name 'php-server' -Target 'Start-PhpServer'
    Set-AgentModeAlias -Name 'composer' -Target 'Invoke-Composer'
    Set-AgentModeAlias -Name 'composer-outdated' -Target 'Test-ComposerOutdated'
    Set-AgentModeAlias -Name 'composer-update' -Target 'Update-ComposerPackages'
    Set-AgentModeAlias -Name 'composer-self-update' -Target 'Update-ComposerSelf'
}
else {
    Set-Alias -Name 'php' -Value 'Invoke-Php' -ErrorAction SilentlyContinue
    Set-Alias -Name 'php-server' -Value 'Start-PhpServer' -ErrorAction SilentlyContinue
    Set-Alias -Name 'composer' -Value 'Invoke-Composer' -ErrorAction SilentlyContinue
    Set-Alias -Name 'composer-outdated' -Value 'Test-ComposerOutdated' -ErrorAction SilentlyContinue
    Set-Alias -Name 'composer-update' -Value 'Update-ComposerPackages' -ErrorAction SilentlyContinue
    Set-Alias -Name 'composer-self-update' -Value 'Update-ComposerSelf' -ErrorAction SilentlyContinue
}

# Composer add - add packages
<#
.SYNOPSIS
    Adds packages to Composer project.
.DESCRIPTION
    Adds packages to composer.json. Supports --dev flag.
.PARAMETER Packages
    Package names to add.
.PARAMETER Dev
    Add as dev dependency (--dev).
.EXAMPLE
    Add-ComposerPackage monolog/monolog
    Adds monolog as a production dependency.
.EXAMPLE
    Add-ComposerPackage phpunit/phpunit -Dev
    Adds phpunit as a dev dependency.
#>
function Add-ComposerPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
        [string[]]$Packages,
        [switch]$Dev
    )
    
    if (Test-CachedCommand composer) {
        $args = @()
        if ($Dev) {
            $args += '--dev'
        }
        & composer require @args @Packages
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'composer' -ToolType 'php-package' -DefaultInstallCommand 'scoop install composer'
        }
        else {
            'Install with: scoop install composer'
        }
        Write-MissingToolWarning -Tool 'composer' -InstallHint $installHint
    }
}

# Composer remove - remove packages
<#
.SYNOPSIS
    Removes packages from Composer project.
.DESCRIPTION
    Removes packages from composer.json. Supports --dev flag.
.PARAMETER Packages
    Package names to remove.
.PARAMETER Dev
    Remove from dev dependencies (--dev).
.EXAMPLE
    Remove-ComposerPackage monolog/monolog
    Removes monolog from production dependencies.
.EXAMPLE
    Remove-ComposerPackage phpunit/phpunit -Dev
    Removes phpunit from dev dependencies.
#>
function Remove-ComposerPackage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, ValueFromRemainingArguments = $true)]
        [string[]]$Packages,
        [switch]$Dev
    )
    
    if (Test-CachedCommand composer) {
        $args = @()
        if ($Dev) {
            $args += '--dev'
        }
        & composer remove @args @Packages
    }
    else {
        $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
            Get-PreferenceAwareInstallHint -ToolName 'composer' -ToolType 'php-package' -DefaultInstallCommand 'scoop install composer'
        }
        else {
            'Install with: scoop install composer'
        }
        Write-MissingToolWarning -Tool 'composer' -InstallHint $installHint
    }
}

# Create aliases for composer add/remove
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'composer-require' -Target 'Add-ComposerPackage'
    Set-AgentModeAlias -Name 'composer-add' -Target 'Add-ComposerPackage'
    Set-AgentModeAlias -Name 'composer-remove' -Target 'Remove-ComposerPackage'
}
else {
    Set-Alias -Name 'composer-require' -Value 'Add-ComposerPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'composer-add' -Value 'Add-ComposerPackage' -ErrorAction SilentlyContinue
    Set-Alias -Name 'composer-remove' -Value 'Remove-ComposerPackage' -ErrorAction SilentlyContinue
}
