<#
scripts/lib/ModuleImport.psm1

.SYNOPSIS
    Module import utilities for scripts/lib modules.

.DESCRIPTION
    Provides functions for resolving paths to scripts/lib modules and importing them
    consistently across scripts in different locations (scripts/utils/, scripts/checks/,
    scripts/git/, scripts/lib/, etc.). This eliminates the need for manual path resolution
    and reduces errors from incorrect path calculations.

.NOTES
    Module Version: 1.0.0
    PowerShell Version: 3.0+
#>

# Import dependencies (PathResolution for Get-RepoRoot, Cache for caching support)
$pathResolutionModulePath = Join-Path $PSScriptRoot 'PathResolution.psm1'
$cacheModulePath = Join-Path $PSScriptRoot 'Cache.psm1'

if (Test-Path $pathResolutionModulePath) {
    Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
if (Test-Path $cacheModulePath) {
    Import-Module $cacheModulePath -ErrorAction SilentlyContinue
}

<#
.SYNOPSIS
    Gets the scripts/lib directory path.

.DESCRIPTION
    Resolves the path to the scripts/lib directory relative to the calling script.
    Works with scripts in any scripts/ subdirectory (e.g., scripts/utils/, scripts/utils/code-quality/,
    scripts/checks/, scripts/git/, scripts/lib/). Scripts should pass their own $PSScriptRoot
    when calling this function.

.PARAMETER ScriptPath
    Path to the script calling this function. Should be $PSScriptRoot from the calling script.

.OUTPUTS
    System.String. The absolute path to the scripts/lib directory.

.EXAMPLE
    $libPath = Get-LibPath -ScriptPath $PSScriptRoot
    Import-Module (Join-Path $libPath 'Logging.psm1') -DisableNameChecking -ErrorAction Stop

.EXAMPLE
    $libPath = Get-LibPath -ScriptPath $PSScriptRoot
    $modulePath = Join-Path $libPath 'ExitCodes.psm1'
    if (Test-Path $modulePath) {
        Import-Module $modulePath -DisableNameChecking -ErrorAction Stop
    }
#>
function Get-LibPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$ScriptPath
    )

    # Cache lib path resolution (1 hour TTL since directory structure rarely changes)
    $cacheKey = "LibPath_$ScriptPath"
    if (Get-Command Get-CachedValue -ErrorAction SilentlyContinue) {
        $cachedResult = Get-CachedValue -Key $cacheKey
        if ($null -ne $cachedResult) {
            return $cachedResult
        }
    }

    # Resolve repository root first, then construct scripts/lib path
    if (-not (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue)) {
        throw "Get-RepoRoot function not available. PathResolution module may not be loaded."
    }

    try {
        $repoRoot = Get-RepoRoot -ScriptPath $ScriptPath
        $libPath = Join-Path $repoRoot 'scripts' 'lib'

        # Verify scripts/lib directory exists
        if (-not (Test-Path $libPath)) {
            throw "scripts/lib directory not found at: $libPath"
        }

        # Normalize to absolute path
        $resolvedLibPath = (Resolve-Path $libPath).Path

        # Cache result for future lookups
        if (Get-Command Set-CachedValue -ErrorAction SilentlyContinue) {
            Set-CachedValue -Key $cacheKey -Value $resolvedLibPath -ExpirationSeconds 3600
        }

        return $resolvedLibPath
    }
    catch {
        throw "Failed to resolve scripts/lib path: $($_.Exception.Message)"
    }
}

<#
.SYNOPSIS
    Imports a module from scripts/lib.

.DESCRIPTION
    Imports a PowerShell module from the scripts/lib directory. This function handles
    path resolution automatically, eliminating the need for manual path calculations.
    Supports optional error handling and module existence checking.

.PARAMETER ModuleName
    Name of the module to import (without .psm1 extension). For example, 'Logging' or 'ExitCodes'.

.PARAMETER ScriptPath
    Path to the script calling this function. Should be $PSScriptRoot from the calling script.
    If not specified, attempts to auto-detect from call stack.

.PARAMETER DisableNameChecking
    If specified, disables name checking during import (equivalent to Import-Module -DisableNameChecking).

.PARAMETER ErrorAction
    Action to take if import fails. Defaults to 'Stop'. Use 'SilentlyContinue' to ignore errors.

.PARAMETER Required
    If specified, throws an error if the module file is not found. Defaults to $true.

.OUTPUTS
    System.Management.Automation.PSModuleInfo. The imported module object.

.EXAMPLE
    Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot

.EXAMPLE
    # Auto-detect script path (ScriptPath optional)
    Import-LibModule -ModuleName 'ExitCodes'

.EXAMPLE
    Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking

.EXAMPLE
    # Import multiple modules (use Import-LibModules for better performance)
    Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot
    Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot
    Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot

.EXAMPLE
    # Optional import (doesn't throw if missing)
    Import-LibModule -ModuleName 'OptionalModule' -ScriptPath $PSScriptRoot -Required:$false -ErrorAction SilentlyContinue
#>
function Import-LibModule {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSModuleInfo])]
    param(
        [Parameter(Mandatory)]
        [string]$ModuleName,

        [string]$ScriptPath,

        [switch]$DisableNameChecking,

        [switch]$Global,

        [bool]$Required = $true
    )

    # Auto-detect script path from call stack if not provided
    if (-not $ScriptPath) {
        $callStack = Get-PSCallStack
        foreach ($frame in $callStack) {
            if ($frame.ScriptName -and $frame.ScriptName -ne $PSCommandPath) {
                # Skip this module's own file
                if ($frame.ScriptName -notlike '*ModuleImport.psm1') {
                    $ScriptPath = $frame.ScriptName
                    break
                }
            }
        }

        # Fallback: try to get from InvocationInfo
        if (-not $ScriptPath) {
            $invocation = $MyInvocation
            if ($invocation -and $invocation.PSCommandPath) {
                $ScriptPath = $invocation.PSCommandPath
            }
        }

        if (-not $ScriptPath) {
            throw "Could not auto-detect script path. Please provide -ScriptPath parameter."
        }
    }

    # Resolve scripts/lib directory path
    try {
        $libPath = Get-LibPath -ScriptPath $ScriptPath
    }
    catch {
        if ($Required) {
            throw "Failed to resolve scripts/lib path: $($_.Exception.Message)"
        }
        return $null
    }

    # Construct full module file path (handle both with and without .psm1 extension)
    $moduleFileName = if ($ModuleName.EndsWith('.psm1')) {
        $ModuleName
    }
    else {
        "$ModuleName.psm1"
    }
    $modulePath = Join-Path $libPath $moduleFileName

    # Get ErrorAction preference from common parameters
    $errorActionPreference = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $PSBoundParameters['ErrorAction']
    }
    else {
        'Stop'
    }

    # Verify module file exists before attempting import
    if (-not (Test-Path $modulePath)) {
        if ($Required) {
            throw "Module '$ModuleName' not found at: $modulePath"
        }
        if ($errorActionPreference -ne 'SilentlyContinue') {
            Write-Warning "Module '$ModuleName' not found at: $modulePath"
        }
        return $null
    }

    # Import module with specified parameters
    try {
        $importParams = @{
            ErrorAction = $errorActionPreference
            PassThru    = $true
        }
        if ($DisableNameChecking) {
            $importParams['DisableNameChecking'] = $true
        }
        if ($Global) {
            $importParams['Global'] = $true
        }
        
        $importedModule = Import-Module $modulePath @importParams
        return $importedModule
    }
    catch {
        if ($Required -or $errorActionPreference -eq 'Stop') {
            throw "Failed to import module '$ModuleName' from $modulePath : $($_.Exception.Message)"
        }
        return $null
    }
}

<#
.SYNOPSIS
    Imports multiple modules from scripts/lib in a single call.

.DESCRIPTION
    Imports multiple PowerShell modules from the scripts/lib directory in a single call.
    This reduces boilerplate when importing multiple modules. Each module is imported
    with the same parameters (DisableNameChecking, Required, ErrorAction).

.PARAMETER ModuleNames
    Array of module names to import (without .psm1 extension). For example, @('ExitCodes', 'Logging').

.PARAMETER ScriptPath
    Path to the script calling this function. Should be $PSScriptRoot from the calling script.

.PARAMETER DisableNameChecking
    If specified, disables name checking during import for all modules.

.PARAMETER Required
    If specified, throws an error if any module file is not found. Defaults to $true.

.PARAMETER ErrorAction
    Action to take if import fails. Defaults to 'Stop'. Use 'SilentlyContinue' to ignore errors.

.OUTPUTS
    System.Management.Automation.PSModuleInfo[]. Array of imported module objects.

.EXAMPLE
    Import-LibModules -ModuleNames @('ExitCodes', 'PathResolution', 'Logging') -ScriptPath $PSScriptRoot

.EXAMPLE
    # Auto-detect script path (ScriptPath optional)
    Import-LibModules -ModuleNames @('ExitCodes', 'PathResolution', 'Logging')

.EXAMPLE
    Import-LibModules -ModuleNames @('ExitCodes', 'Logging') -ScriptPath $PSScriptRoot -DisableNameChecking

.EXAMPLE
    # Optional imports (doesn't throw if missing)
    Import-LibModules -ModuleNames @('OptionalModule1', 'OptionalModule2') -ScriptPath $PSScriptRoot -Required:$false
#>
function Import-LibModules {
    [CmdletBinding()]
    [OutputType([System.Management.Automation.PSModuleInfo[]])]
    param(
        [Parameter(Mandatory)]
        [string[]]$ModuleNames,

        [string]$ScriptPath,

        [switch]$DisableNameChecking,

        [bool]$Required = $true
    )

    # Auto-detect script path from call stack if not provided
    if (-not $ScriptPath) {
        $callStack = Get-PSCallStack
        foreach ($frame in $callStack) {
            if ($frame.ScriptName -and $frame.ScriptName -ne $PSCommandPath) {
                # Skip this module's own file
                if ($frame.ScriptName -notlike '*ModuleImport.psm1') {
                    $ScriptPath = $frame.ScriptName
                    break
                }
            }
        }

        # Fallback: try to get from InvocationInfo
        if (-not $ScriptPath) {
            $invocation = $MyInvocation
            if ($invocation -and $invocation.PSCommandPath) {
                $ScriptPath = $invocation.PSCommandPath
            }
        }

        if (-not $ScriptPath) {
            throw "Could not auto-detect script path. Please provide -ScriptPath parameter."
        }
    }

    # Get ErrorAction preference (from CmdletBinding common parameter)
    $errorActionPreference = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $PSBoundParameters['ErrorAction']
    }
    else {
        'Stop'
    }

    $importedModules = @()
    $failedModules = @()

    foreach ($moduleName in $ModuleNames) {
        try {
            $params = @{
                ModuleName  = $moduleName
                ScriptPath  = $ScriptPath
                Required    = $Required
                ErrorAction = $errorActionPreference
            }

            if ($DisableNameChecking) {
                $params['DisableNameChecking'] = $true
            }

            $module = Import-LibModule @params
            if ($null -ne $module) {
                $importedModules += $module
            }
            elseif ($Required) {
                $failedModules += $moduleName
            }
        }
        catch {
            if ($Required) {
                $failedModules += $moduleName
                if ($errorActionPreference -eq 'Stop') {
                    throw "Failed to import module '$moduleName': $($_.Exception.Message)"
                }
            }
        }
    }

    if ($failedModules.Count -gt 0 -and $Required) {
        throw "Failed to import $($failedModules.Count) module(s): $($failedModules -join ', ')"
    }

    return $importedModules
}

<#
.SYNOPSIS
    Initializes script environment with common modules and paths.

.DESCRIPTION
    One-stop function for script initialization that:
    - Auto-detects script path from call stack (if not provided)
    - Imports requested library modules
    - Optionally gets repository root and profile directory
    - Returns an object with common paths and imported modules

    This significantly reduces boilerplate code in utility scripts.

.PARAMETER ScriptPath
    Path to the script calling this function. If not specified, attempts to detect from call stack.
    Should be $PSScriptRoot from the calling script for best results.

.PARAMETER ImportModules
    Array of module names to import from scripts/lib. Common modules: 'ExitCodes', 'PathResolution', 'Logging', 'Module'.

.PARAMETER GetRepoRoot
    If specified, gets and returns the repository root path.

.PARAMETER GetProfileDir
    If specified, gets and returns the profile.d directory path.

.PARAMETER DisableNameChecking
    If specified, disables name checking during module imports.

.PARAMETER ExitOnError
    If specified, exits the script with EXIT_SETUP_ERROR if initialization fails.
    Requires ExitCodes module to be imported (or included in ImportModules).

.OUTPUTS
    PSCustomObject. Object with properties:
    - ScriptPath: The script path used
    - RepoRoot: Repository root (if GetRepoRoot specified)
    - ProfileDir: Profile directory (if GetProfileDir specified)
    - LibPath: Path to scripts/lib directory
    - ImportedModules: Array of imported module objects

.EXAMPLE
    # Minimal initialization - just get repo root
    $env = Initialize-ScriptEnvironment -GetRepoRoot
    $repoRoot = $env.RepoRoot

.EXAMPLE
    # Common initialization with modules
    $env = Initialize-ScriptEnvironment `
        -ImportModules @('ExitCodes', 'PathResolution', 'Logging') `
        -GetRepoRoot `
        -DisableNameChecking

    $repoRoot = $env.RepoRoot
    # ExitCodes, PathResolution, and Logging modules are now imported

.EXAMPLE
    # Full initialization with error handling
    $env = Initialize-ScriptEnvironment `
        -ScriptPath $PSScriptRoot `
        -ImportModules @('ExitCodes', 'PathResolution', 'Logging', 'Module') `
        -GetRepoRoot `
        -GetProfileDir `
        -DisableNameChecking `
        -ExitOnError

    $repoRoot = $env.RepoRoot
    $profileDir = $env.ProfileDir

.EXAMPLE
    # Auto-detect script path from call stack
    $env = Initialize-ScriptEnvironment -ImportModules @('ExitCodes', 'Logging') -GetRepoRoot
    # ScriptPath is automatically detected
#>
function Initialize-ScriptEnvironment {
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [string]$ScriptPath,

        [string[]]$ImportModules = @(),

        [switch]$GetRepoRoot,

        [switch]$GetProfileDir,

        [switch]$DisableNameChecking,

        [switch]$ExitOnError
    )

    # Auto-detect script path from call stack if not provided
    if (-not $ScriptPath) {
        $callStack = Get-PSCallStack
        foreach ($frame in $callStack) {
            if ($frame.ScriptName -and $frame.ScriptName -ne $PSCommandPath) {
                # Skip this module's own file
                if ($frame.ScriptName -notlike '*ModuleImport.psm1') {
                    $ScriptPath = $frame.ScriptName
                    break
                }
            }
        }

        # Fallback: try to get from InvocationInfo
        if (-not $ScriptPath) {
            $invocation = $MyInvocation
            if ($invocation -and $invocation.PSCommandPath) {
                $ScriptPath = $invocation.PSCommandPath
            }
        }

        if (-not $ScriptPath) {
            $errorMessage = "Could not auto-detect script path. Please provide -ScriptPath parameter."
            if ($ExitOnError) {
                if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
                    if (Get-Variable EXIT_SETUP_ERROR -ErrorAction SilentlyContinue) {
                        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message $errorMessage
                    }
                    else {
                        Exit-WithCode -ExitCode 2 -Message $errorMessage
                    }
                }
                else {
                    Write-Error $errorMessage -ErrorAction Stop
                    exit 2
                }
            }
            throw $errorMessage
        }
    }

    # Resolve script path to absolute
    try {
        if (Test-Path $ScriptPath) {
            $ScriptPath = (Resolve-Path $ScriptPath).Path
        }
        elseif (Test-Path (Split-Path -Parent $ScriptPath)) {
            $parentDir = (Resolve-Path (Split-Path -Parent $ScriptPath)).Path
            $ScriptPath = Join-Path $parentDir (Split-Path -Leaf $ScriptPath)
        }
    }
    catch {
        $errorMessage = "Failed to resolve script path '$ScriptPath': $($_.Exception.Message)"
        if ($ExitOnError) {
            if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
                if (Get-Variable EXIT_SETUP_ERROR -ErrorAction SilentlyContinue) {
                    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message $errorMessage
                }
                else {
                    Exit-WithCode -ExitCode 2 -Message $errorMessage
                }
            }
            else {
                Write-Error $errorMessage -ErrorAction Stop
                exit 2
            }
        }
        throw $errorMessage
    }

    # Get lib path
    try {
        $libPath = Get-LibPath -ScriptPath $ScriptPath
    }
    catch {
        $errorMessage = "Failed to resolve scripts/lib path: $($_.Exception.Message)"
        if ($ExitOnError) {
            if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
                if (Get-Variable EXIT_SETUP_ERROR -ErrorAction SilentlyContinue) {
                    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message $errorMessage
                }
                else {
                    Exit-WithCode -ExitCode 2 -Message $errorMessage
                }
            }
            else {
                Write-Error $errorMessage -ErrorAction Stop
                exit 2
            }
        }
        throw $errorMessage
    }

    # Import requested modules
    $importedModules = @()
    if ($ImportModules.Count -gt 0) {
        try {
            $params = @{
                ModuleNames = $ImportModules
                ScriptPath  = $ScriptPath
            }

            if ($DisableNameChecking) {
                $params['DisableNameChecking'] = $true
            }

            $importedModules = Import-LibModules @params
        }
        catch {
            $errorMessage = "Failed to import modules: $($_.Exception.Message)"
            if ($ExitOnError) {
                if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
                    if (Get-Variable EXIT_SETUP_ERROR -ErrorAction SilentlyContinue) {
                        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message $errorMessage
                    }
                    else {
                        Exit-WithCode -ExitCode 2 -Message $errorMessage
                    }
                }
                else {
                    Write-Error $errorMessage -ErrorAction Stop
                    exit 2
                }
            }
            throw $errorMessage
        }
    }

    # Get repository root if requested
    $repoRoot = $null
    if ($GetRepoRoot) {
        try {
            if (Get-Command Get-RepoRootSafe -ErrorAction SilentlyContinue) {
                $repoRoot = Get-RepoRootSafe -ScriptPath $ScriptPath -ExitOnError:$ExitOnError
            }
            elseif (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                $repoRoot = Get-RepoRoot -ScriptPath $ScriptPath
            }
            else {
                throw "Get-RepoRoot function not available. Import PathResolution module first."
            }
        }
        catch {
            $errorMessage = "Failed to get repository root: $($_.Exception.Message)"
            if ($ExitOnError) {
                if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
                    if (Get-Variable EXIT_SETUP_ERROR -ErrorAction SilentlyContinue) {
                        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message $errorMessage
                    }
                    else {
                        Exit-WithCode -ExitCode 2 -Message $errorMessage
                    }
                }
                else {
                    Write-Error $errorMessage -ErrorAction Stop
                    exit 2
                }
            }
            throw $errorMessage
        }
    }

    # Get profile directory if requested
    $profileDir = $null
    if ($GetProfileDir) {
        try {
            if (-not $repoRoot) {
                if (Get-Command Get-RepoRootSafe -ErrorAction SilentlyContinue) {
                    $repoRoot = Get-RepoRootSafe -ScriptPath $ScriptPath -ExitOnError:$ExitOnError
                }
                elseif (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    $repoRoot = Get-RepoRoot -ScriptPath $ScriptPath
                }
            }

            if ($repoRoot) {
                $profileDir = Join-Path $repoRoot 'profile.d'
            }
            elseif (Get-Command Get-ProfileDirectory -ErrorAction SilentlyContinue) {
                $profileDir = Get-ProfileDirectory -ScriptPath $ScriptPath
            }
            else {
                throw "Could not determine profile directory. Repository root not available."
            }
        }
        catch {
            $errorMessage = "Failed to get profile directory: $($_.Exception.Message)"
            if ($ExitOnError) {
                if (Get-Command Exit-WithCode -ErrorAction SilentlyContinue) {
                    if (Get-Variable EXIT_SETUP_ERROR -ErrorAction SilentlyContinue) {
                        Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -Message $errorMessage
                    }
                    else {
                        Exit-WithCode -ExitCode 2 -Message $errorMessage
                    }
                }
                else {
                    Write-Error $errorMessage -ErrorAction Stop
                    exit 2
                }
            }
            throw $errorMessage
        }
    }

    # Return environment object
    return [PSCustomObject]@{
        ScriptPath      = $ScriptPath
        RepoRoot        = $repoRoot
        ProfileDir      = $profileDir
        LibPath         = $libPath
        ImportedModules = $importedModules
    }
}

Export-ModuleMember -Function @(
    'Get-LibPath',
    'Import-LibModule',
    'Import-LibModules',
    'Initialize-ScriptEnvironment'
)

