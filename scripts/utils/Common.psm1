<#
scripts/utils/Common.psm1

.SYNOPSIS
    Shared utility functions for PowerShell profile scripts.

.DESCRIPTION
    Provides common functionality used across multiple utility scripts including:
    - Repository root path resolution
    - Module installation and management
    - Command availability checking
    - Directory creation and path validation
    - PowerShell executable detection
    - Consistent output formatting
    - Standardized exit code handling

.NOTES
    This module is designed to be imported by utility scripts in the scripts/ directory.
    It uses $PSScriptRoot for path resolution, which requires PowerShell 3.0+.
    
    Module Version: 1.0.0
    PowerShell Version: 3.0+
    Author: PowerShell Profile Project

.EXAMPLE
    Import-Module -Path (Join-Path $PSScriptRoot 'Common.psm1')
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
#>

# Exit code constants
# These match the standardized exit code conventions documented in CONTRIBUTING.md
$script:EXIT_SUCCESS = 0              # Success
$script:EXIT_VALIDATION_FAILURE = 1    # Validation/check failure (expected)
$script:EXIT_SETUP_ERROR = 2           # Setup/configuration error (unexpected)
$script:EXIT_OTHER_ERROR = 3          # Other errors

<#
.SYNOPSIS
    Gets the repository root directory path.

.DESCRIPTION
    Calculates the repository root directory path relative to the calling script.
    Works with scripts in scripts/utils/, scripts/checks/, and scripts/git/ directories.
    Scripts should pass their own $PSScriptRoot when calling this function.

.PARAMETER ScriptPath
    Path to the script calling this function. Should be $PSScriptRoot from the calling script.

.OUTPUTS
    System.String. The absolute path to the repository root directory.

.EXAMPLE
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    $profileDir = Join-Path $repoRoot 'profile.d'
#>
function Get-RepoRoot {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    # If called from scripts/utils/ or scripts/checks/, go up two levels
    # If called from scripts/git/, also go up two levels
    $scriptDir = Split-Path -Parent $ScriptPath
    $repoRoot = Split-Path -Parent $scriptDir

    if (-not (Test-Path $repoRoot)) {
        throw "Repository root not found at: $repoRoot. Ensure the script is located in scripts/utils/, scripts/checks/, or scripts/git/ directory."
    }

    return $repoRoot
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

<#
.SYNOPSIS
    Tests if a command is available on the system.

.DESCRIPTION
    Checks if a command (executable, function, cmdlet, or alias) is available.
    Uses Test-HasCommand if available from profile, otherwise falls back to Get-Command.
    This provides a consistent way to check command availability across scripts.

.PARAMETER CommandName
    The name of the command to check.

.OUTPUTS
    System.Boolean. Returns $true if command is available, $false otherwise.

.EXAMPLE
    if (Test-CommandAvailable -CommandName 'git') {
        & git --version
    }
#>
function Test-CommandAvailable {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName
    )

    # Use Test-HasCommand if available from profile (more efficient)
    if ((Test-Path Function:Test-HasCommand) -or (Get-Command Test-HasCommand -ErrorAction SilentlyContinue)) {
        return Test-HasCommand $CommandName
    }

    # Fallback to Get-Command
    return $null -ne (Get-Command $CommandName -ErrorAction SilentlyContinue)
}

<#
.SYNOPSIS
    Ensures a directory exists, creating it if necessary.

.DESCRIPTION
    Checks if a directory exists, and creates it if it doesn't. Useful for
    ensuring output directories exist before writing files. Throws an error
    if directory creation fails.

.PARAMETER Path
    The directory path to ensure exists.

.PARAMETER ErrorMessage
    Custom error message to use if directory creation fails.

.EXAMPLE
    Ensure-DirectoryExists -Path (Join-Path $repoRoot 'scripts' 'data')
#>
function Ensure-DirectoryExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [string]$ErrorMessage
    )

    if (-not (Test-Path -Path $Path)) {
        try {
            New-Item -ItemType Directory -Path $Path -Force | Out-Null
            Write-Verbose "Created directory: $Path"
        }
        catch {
            if (-not $ErrorMessage) {
                $ErrorMessage = "Failed to create directory: $Path"
            }
            throw $ErrorMessage
        }
    }
    elseif (-not (Test-Path -Path $Path -PathType Container)) {
        throw "Path exists but is not a directory: $Path"
    }
}

<#
.SYNOPSIS
    Gets the appropriate PowerShell executable name for the current environment.

.DESCRIPTION
    Returns 'pwsh' for PowerShell Core or 'powershell' for Windows PowerShell.
    Useful for scripts that need to spawn PowerShell processes.

.OUTPUTS
    System.String. The PowerShell executable name ('pwsh' or 'powershell').

.EXAMPLE
    $psExe = Get-PowerShellExecutable
    & $psExe -NoProfile -File $scriptPath
#>
function Get-PowerShellExecutable {
    [CmdletBinding()]
    param()

    if ($PSVersionTable.PSEdition -eq 'Core') {
        return 'pwsh'
    }
    else {
        return 'powershell'
    }
}

<#
.SYNOPSIS
    Tests if a path exists and throws an error if it doesn't.

.DESCRIPTION
    Validates that a file or directory path exists. Throws a descriptive error
    if the path is not found. Useful for parameter validation and early error detection.

.PARAMETER Path
    The path to test.

.PARAMETER PathType
    The type of path to validate. 'Any' (default), 'File', or 'Directory'.

.PARAMETER ErrorMessage
    Custom error message to use if path doesn't exist. If not provided, a default
    message is generated.

.EXAMPLE
    Test-PathExists -Path $configFile -PathType 'File'

.EXAMPLE
    Test-PathExists -Path $outputDir -PathType 'Directory' -ErrorMessage "Output directory not found"
#>
function Test-PathExists {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Path,

        [ValidateSet('Any', 'File', 'Directory')]
        [string]$PathType = 'Any',

        [string]$ErrorMessage
    )

    if (-not (Test-Path -Path $Path)) {
        if (-not $ErrorMessage) {
            $typeLabel = switch ($PathType) {
                'File' { 'file' }
                'Directory' { 'directory' }
                default { 'path' }
            }
            $ErrorMessage = "$typeLabel not found: $Path"
        }
        throw $ErrorMessage
    }

    if ($PathType -eq 'File' -and -not (Test-Path -Path $Path -PathType Leaf)) {
        throw "Path exists but is not a file: $Path"
    }

    if ($PathType -eq 'Directory' -and -not (Test-Path -Path $Path -PathType Container)) {
        throw "Path exists but is not a directory: $Path"
    }

    return $true
}

<#
.SYNOPSIS
    Validates that required parameters are not null or empty.

.DESCRIPTION
    Helper function to validate required parameters with consistent error messages.
    Throws an error if any parameter is null or empty.

.PARAMETER Parameters
    Hashtable of parameter names and values to validate.

.EXAMPLE
    Test-RequiredParameters -Parameters @{ Path = $Path; Name = $Name }
#>
function Test-RequiredParameters {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [hashtable]$Parameters
    )

    foreach ($key in $Parameters.Keys) {
        $value = $Parameters[$key]
        if ($null -eq $value -or ($value -is [string] -and [string]::IsNullOrWhiteSpace($value))) {
            throw "Required parameter '$key' is null or empty."
        }
    }

    return $true
}

<#
.SYNOPSIS
    Writes a formatted message to the output stream.

.DESCRIPTION
    Provides consistent message formatting for utility scripts.
    Uses Write-Output for pipeline compatibility.

.PARAMETER Message
    The message to write.

.PARAMETER ForegroundColor
    Optional foreground color for the message (for Write-Host compatibility).

.PARAMETER IsWarning
    If specified, writes the message as a warning using Write-Warning.

.PARAMETER IsError
    If specified, writes the message as an error using Write-Error.

.EXAMPLE
    Write-ScriptMessage -Message "Running analysis..."

.EXAMPLE
    Write-ScriptMessage -Message "Warning: deprecated feature" -IsWarning

.EXAMPLE
    Write-ScriptMessage -Message "Error: validation failed" -IsError
#>
function Write-ScriptMessage {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Message,

        [System.ConsoleColor]$ForegroundColor,

        [switch]$IsWarning,

        [switch]$IsError
    )

    if ($IsError) {
        Write-Error $Message
    }
    elseif ($IsWarning) {
        Write-Warning $Message
    }
    elseif ($ForegroundColor) {
        Write-Host $Message -ForegroundColor $ForegroundColor
    }
    else {
        Write-Output $Message
    }
}

<#
.SYNOPSIS
    Exits the script with a standardized exit code.

.DESCRIPTION
    Exits the script with a standardized exit code and optional message.
    This ensures consistent exit code usage across all utility scripts.

.PARAMETER ExitCode
    The exit code to use. Use constants: EXIT_SUCCESS, EXIT_VALIDATION_FAILURE, EXIT_SETUP_ERROR.

.PARAMETER Message
    Optional message to display before exiting.

.PARAMETER ErrorRecord
    Optional error record to display before exiting.

.EXAMPLE
    Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Validation failed"

.EXAMPLE
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
#>
function Exit-WithCode {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [int]$ExitCode,

        [string]$Message,

        [System.Management.Automation.ErrorRecord]$ErrorRecord
    )

    if ($Message) {
        Write-Output $Message
    }

    if ($ErrorRecord) {
        Write-Error $ErrorRecord
    }

    exit $ExitCode
}

# Export functions
Export-ModuleMember -Function @(
    'Get-RepoRoot',
    'Install-RequiredModule',
    'Import-RequiredModule',
    'Ensure-ModuleAvailable',
    'Test-CommandAvailable',
    'Ensure-DirectoryExists',
    'Get-PowerShellExecutable',
    'Test-PathExists',
    'Test-RequiredParameters',
    'Write-ScriptMessage',
    'Exit-WithCode'
)

# Export exit code constants as variables (read-only)
Export-ModuleMember -Variable @(
    'EXIT_SUCCESS',
    'EXIT_VALIDATION_FAILURE',
    'EXIT_SETUP_ERROR',
    'EXIT_OTHER_ERROR'
)

