<#
scripts/lib/Module.psm1

.SYNOPSIS
    PowerShell module installation and management utilities.

.DESCRIPTION
    Provides functions for installing, importing, and managing PowerShell modules
    with automatic PSGallery registration and trust configuration.

.NOTES
    Module Version: 2.0.0
    PowerShell Version: 5.0+ (for enum support)
    
    This module now uses enums for type-safe scope handling.
#>

# Import CommonEnums for ModuleScope enum
$commonEnumsPath = Join-Path (Split-Path -Parent $PSScriptRoot) 'core' 'CommonEnums.psm1'
if ($commonEnumsPath -and (Test-Path -LiteralPath $commonEnumsPath)) {
    Import-Module $commonEnumsPath -DisableNameChecking -ErrorAction SilentlyContinue
}

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
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [ModuleScope]$Scope = [ModuleScope]::CurrentUser,

        [switch]$Force
    )

    # Check if module is already available
    $moduleAvailable = Get-Module -ListAvailable -Name $ModuleName -ErrorAction SilentlyContinue
    if ($moduleAvailable -and -not $Force) {
        $debugLevel = 0
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[module.install] $ModuleName is already installed (version $($moduleAvailable.Version))"
        }
        # Level 3: Log detailed module information
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Host "  [module.install] Module details - Name: $ModuleName, Version: $($moduleAvailable.Version), Path: $($moduleAvailable.Path)" -ForegroundColor DarkGray
        }
        return
    }

    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
        Write-Verbose "[module.install] $ModuleName not found. Installing to $Scope scope..."
    }
    Write-Output "$ModuleName not found. Installing to $Scope scope..."

    try {
        # Ensure PSGallery is registered and trusted
        $psGallery = Get-PSRepository -Name PSGallery -ErrorAction SilentlyContinue
        if (-not $psGallery) {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                Write-Verbose "[module.install] Registering PSGallery repository..."
            }
            Register-PSRepository -Default -ErrorAction Stop
        }
        # Set PSGallery as trusted if not already
        if ($psGallery.InstallationPolicy -ne 'Trusted') {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
                Write-Verbose "[module.install] Setting PSGallery as trusted..."
            }
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
        
        # Level 3: Log detailed installation parameters
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            Write-Host "  [module.install] Installation parameters - Name: $ModuleName, Scope: $Scope, Force: $true" -ForegroundColor DarkGray
        }

        Install-Module @installParams

        # Level 2: Log successful installation
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[module.install] $ModuleName installed successfully"
        }
    }
    catch {
        $debugLevel = 0
        $hasDebug = $false
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            $hasDebug = $debugLevel -ge 1
        }
        
        if ($hasDebug) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'module.install' -Context @{
                    ModuleName = $ModuleName
                    Scope      = $Scope
                    Force      = $Force
                }
            }
            else {
                Write-Error "Failed to install module $ModuleName`: $($_.Exception.Message)"
            }
            # Level 3: Log detailed error information
            if ($debugLevel -ge 3) {
                Write-Host "  [module.install] Installation error details - ModuleName: $ModuleName, Scope: $Scope, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
        else {
            # Always log critical errors even if debug is off
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'module.install' -Context @{
                    ModuleName = $ModuleName
                    Scope      = $Scope
                    Force      = $Force
                    ErrorType  = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to install module $ModuleName`: $($_.Exception.Message)"
            }
        }
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

    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
        Write-Host "  [module.import] Importing module: $ModuleName, Force: $Force" -ForegroundColor DarkGray
    }
    try {
        Import-Module -Name $ModuleName -Force:$Force -ErrorAction Stop
        # Level 2: Log successful import
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 2) {
            Write-Verbose "[module.import] $ModuleName imported successfully"
        }
        # Level 3: Log detailed import information
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel) -and $debugLevel -ge 3) {
            $importedModule = Get-Module -Name $ModuleName
            if ($importedModule) {
                Write-Host "  [module.import] Imported module details - Version: $($importedModule.Version), Path: $($importedModule.Path)" -ForegroundColor DarkGray
            }
        }
    }
    catch {
        $debugLevel = 0
        $hasDebug = $false
        if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
            $hasDebug = $debugLevel -ge 1
        }
        
        if ($hasDebug) {
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'module.import' -Context @{
                    ModuleName = $ModuleName
                    Force      = $Force
                }
            }
            else {
                Write-Error "Failed to import module $ModuleName`: $($_.Exception.Message)"
            }
            # Level 3: Log detailed error information
            if ($debugLevel -ge 3) {
                Write-Host "  [module.import] Import error details - ModuleName: $ModuleName, Force: $Force, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message)" -ForegroundColor DarkGray
            }
        }
        else {
            # Always log critical errors even if debug is off
            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                Write-StructuredError -ErrorRecord $_ -OperationName 'module.import' -Context @{
                    ModuleName = $ModuleName
                    Force      = $Force
                    ErrorType  = $_.Exception.GetType().FullName
                }
            }
            else {
                Write-Error "Failed to import module $ModuleName`: $($_.Exception.Message)"
            }
        }
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
        [ValidateNotNullOrEmpty()]
        [string]$ModuleName,

        [ModuleScope]$Scope = [ModuleScope]::CurrentUser,

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

