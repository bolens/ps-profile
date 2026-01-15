# ===============================================
# laravel.ps1
# Laravel framework helpers
# ===============================================
# Tier: standard
# Dependencies: bootstrap, env
# Environment: web, development

<#
.SYNOPSIS
    Laravel framework helper functions and aliases.

.DESCRIPTION
    Provides PowerShell functions and aliases for common Laravel operations.
    Functions check for artisan/composer availability using Test-CachedCommand for efficient
    command detection without triggering module autoload.

.NOTES
    Module: PowerShell.Profile.Laravel
    Author: PowerShell Profile
#>

# Laravel artisan command - run artisan commands
<#
.SYNOPSIS
    Executes Laravel Artisan commands.

.DESCRIPTION
    Wrapper function for Laravel Artisan CLI that checks for command availability before execution.

.PARAMETER Arguments
    Arguments to pass to artisan.

.EXAMPLE
    Invoke-LaravelArtisan --version

.EXAMPLE
    Invoke-LaravelArtisan make:controller MyController
#>
function Invoke-LaravelArtisan {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand artisan) {
        php artisan @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'artisan' -InstallHint 'Laravel Artisan is typically available in Laravel projects. Ensure you are in a Laravel project directory.'
    }
}

# Laravel artisan alias - run artisan commands
<#
.SYNOPSIS
    Executes Laravel Artisan commands (alias).

.DESCRIPTION
    Alternative wrapper for Laravel Artisan CLI using 'art' command if available.

.PARAMETER Arguments
    Arguments to pass to artisan.

.EXAMPLE
    Invoke-LaravelArt --version

.EXAMPLE
    Invoke-LaravelArt make:model MyModel
#>
function Invoke-LaravelArt {
    [CmdletBinding()]
    param(
        [Parameter(ValueFromRemainingArguments = $true)]
        [string[]]$Arguments
    )
    
    if (Test-CachedCommand art) {
        php artisan @Arguments
    }
    else {
        Write-MissingToolWarning -Tool 'art' -InstallHint 'Laravel Artisan is typically available in Laravel projects. Ensure you are in a Laravel project directory.'
    }
}

# Laravel new project - create new Laravel application
<#
.SYNOPSIS
    Creates a new Laravel application.

.DESCRIPTION
    Wrapper for composer create-project to create a new Laravel application.

.PARAMETER Name
    Name of the new Laravel project.

.EXAMPLE
    New-LaravelApp my-app

.EXAMPLE
    New-LaravelApp my-blog
#>
function New-LaravelApp {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory, Position = 0)]
        [string]$Name
    )
    
    if (Test-CachedCommand composer) {
        composer create-project laravel/laravel $Name
    }
    else {
        Write-MissingToolWarning -Tool 'composer' -InstallHint 'Install with: scoop install composer'
    }
}

# Create aliases for short forms
if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'artisan' -Target 'Invoke-LaravelArtisan'
    Set-AgentModeAlias -Name 'art' -Target 'Invoke-LaravelArt'
    Set-AgentModeAlias -Name 'laravel-new' -Target 'New-LaravelApp'
}
else {
    Set-Alias -Name 'artisan' -Value 'Invoke-LaravelArtisan' -ErrorAction SilentlyContinue
    Set-Alias -Name 'art' -Value 'Invoke-LaravelArt' -ErrorAction SilentlyContinue
    Set-Alias -Name 'laravel-new' -Value 'New-LaravelApp' -ErrorAction SilentlyContinue
}
