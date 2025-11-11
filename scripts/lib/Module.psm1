<#
scripts/lib/Module.psm1

.SYNOPSIS
    PowerShell module installation and management utilities.

.DESCRIPTION
    Provides functions for installing, importing, and managing PowerShell modules
    with automatic PSGallery registration and trust configuration.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

<#
.SYNOPSIS
    Ensures a PowerShell module is installed and available.

.DESCRIPTION
    Checks if a module is available, and if not, installs it to the specified scope.
    Handles PSGallery registration and trust configuration automatically.
    Throws an error if installation fails.

.PARAMETER ModuleName
    The name of the module to ensure is installed.

.PARAMETER Scope
    The installation scope. Defaults to 'CurrentUser'.

.PARAMETER Force
    If specified, forces reinstallation of the module even if it's already installed.

.EXAMPLE
    Install-RequiredModule -ModuleName 'PSScriptAnalyzer'

.EXAMPLE
    Install-RequiredModule -ModuleName 'Pester' -Scope 'CurrentUser'
#>
function Install-RequiredModule {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser',

        [switch]$Force
    )

    # Check if module is already available
    $moduleAvailable = Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue
    if ($moduleAvailable -and -not $Force) {
        Write-Verbose "$ModuleName is already installed (version $($moduleAvailable.Version))"
        return
    }

    Write-Output "$ModuleName not found. Installing to $Scope scope..."

    try {
        # Ensure PSGallery is registered and trusted
        $psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        if (-not $psGallery) {
            Write-Verbose "Registering PSGallery repository..."
            Register-PSRepository -Default -ErrorAction Stop
        }

        # Set PSGallery as trusted if not already
        if ($psGallery.InstallationPolicy -ne 'Trusted') {
            Write-Verbose "Setting PSGallery as trusted..."
            Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction Stop
        }

        # Install the module
        $installParams = @{
            Name         = $ModuleName
            Scope        = $Scope
            Force        = $true
            Confirm      = $false
            ErrorAction  = 'Stop'
            AllowClobber = $true
        }

        Install-Module @installParams

        Write-Verbose "$ModuleName installed successfully"
    }
    catch {
        $errorMessage = "Failed to install $ModuleName`: $($_.Exception.Message). Ensure PowerShell Gallery is accessible and you have permission to install modules."
        Write-Error $errorMessage
        throw
    }
}

<#
.SYNOPSIS
    Imports a PowerShell module with error handling.

.DESCRIPTION
    Imports a PowerShell module and handles import errors gracefully.
    Throws an error if import fails.

.PARAMETER ModuleName
    The name of the module to import.

.PARAMETER Force
    If specified, forces reimport of the module even if already loaded.

.EXAMPLE
    Import-RequiredModule -ModuleName 'PSScriptAnalyzer'
#>
function Import-RequiredModule {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [switch]$Force
    )

    try {
        Import-Module -Name $ModuleName -Force:$Force -ErrorAction Stop
        Write-Verbose "$ModuleName imported successfully"
    }
    catch {
        $errorMessage = "Failed to import $ModuleName`: $($_.Exception.Message). Ensure the module is installed and accessible."
        Write-Error $errorMessage
        throw
    }
}

<#
.SYNOPSIS
    Ensures a module is installed and imported.

.DESCRIPTION
    Convenience function that combines Install-RequiredModule and Import-RequiredModule.
    Ensures the module is available and imported for use.

.PARAMETER ModuleName
    The name of the module to ensure is available.

.PARAMETER Scope
    The installation scope. Defaults to 'CurrentUser'.

.PARAMETER Force
    If specified, forces reinstallation and reimport.

.EXAMPLE
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
#>
function Ensure-ModuleAvailable {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [ValidateSet('CurrentUser', 'AllUsers')]
        [string]$Scope = 'CurrentUser',

        [switch]$Force
    )

    Install-RequiredModule -ModuleName $ModuleName -Scope $Scope -Force:$Force
    Import-RequiredModule -ModuleName $ModuleName -Force:$Force
}

# Export functions
Export-ModuleMember -Function @(
    'Install-RequiredModule',
    'Import-RequiredModule',
    'Ensure-ModuleAvailable'
)

