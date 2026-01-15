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
    
    This module uses strict mode for enhanced error checking.
#>

# Enable strict mode for enhanced error checking
Set-StrictMode -Version Latest

# Import dependencies (PathResolution for Get-RepoRoot, Cache for caching support)
# Note: These are now in subdirectories (path/ and utilities/)
# Use SafeImport module if available for safer imports
$safeImportModulePath = Join-Path $PSScriptRoot 'core' 'SafeImport.psm1'
if ($safeImportModulePath -and -not [string]::IsNullOrWhiteSpace($safeImportModulePath) -and (Test-Path -LiteralPath $safeImportModulePath)) {
    Import-Module $safeImportModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}

# Import ErrorHandling module if available for consistent error action preference handling
$errorHandlingModulePath = Join-Path $PSScriptRoot 'core' 'ErrorHandling.psm1'
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $errorHandlingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($errorHandlingModulePath -and -not [string]::IsNullOrWhiteSpace($errorHandlingModulePath) -and (Test-Path -LiteralPath $errorHandlingModulePath)) {
        Import-Module $errorHandlingModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
}

# Import PathResolution and Cache modules
$pathResolutionModulePath = Join-Path $PSScriptRoot 'path' 'PathResolution.psm1'
$cacheModulePath = Join-Path $PSScriptRoot 'utilities' 'Cache.psm1'

# Use Import-ModuleSafely if available, otherwise fall back to manual check
if (Get-Command Import-ModuleSafely -ErrorAction SilentlyContinue) {
    Import-ModuleSafely -ModulePath $pathResolutionModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    Import-ModuleSafely -ModulePath $cacheModulePath -ErrorAction SilentlyContinue
}
else {
    # Fallback to manual validation
    if ($pathResolutionModulePath -and -not [string]::IsNullOrWhiteSpace($pathResolutionModulePath) -and (Test-Path -LiteralPath $pathResolutionModulePath)) {
        Import-Module $pathResolutionModulePath -DisableNameChecking -ErrorAction SilentlyContinue
    }
    if ($cacheModulePath -and -not [string]::IsNullOrWhiteSpace($cacheModulePath) -and (Test-Path -LiteralPath $cacheModulePath)) {
        Import-Module $cacheModulePath -ErrorAction SilentlyContinue
    }
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
    # Note: Use Import-LibModule instead of direct paths (automatically resolves subdirectories)
    Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking

.EXAMPLE
    # Direct path import (requires subdirectory path)
    $libPath = Get-LibPath -ScriptPath $PSScriptRoot
    $modulePath = Join-Path $libPath 'core' 'ExitCodes.psm1'
    if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
        Import-Module $modulePath -DisableNameChecking -ErrorAction Stop
    }
#>
function Get-LibPath {
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$ScriptPath
    )

    # Validate ScriptPath first before any operations
    if (-not $ScriptPath -or [string]::IsNullOrWhiteSpace($ScriptPath)) {
        throw "ScriptPath cannot be null or empty"
    }
    if ($ScriptPath -isnot [string]) {
        $ScriptPath = [string]$ScriptPath
    }

    # Cache lib path resolution (1 hour TTL since directory structure rarely changes)
    # Use CacheKey module if available for consistent key generation
    $cacheKey = if (Get-Command New-CacheKey -ErrorAction SilentlyContinue) {
        # New-CacheKey expects Components to be an array, wrap single string in array
        New-CacheKey -Prefix 'LibPath' -Components @($ScriptPath)
    }
    else {
        "LibPath_$ScriptPath"
    }
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
        # Use Validation module if available, otherwise fall back to manual check
        if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
            if (-not (Test-ValidPath -Path $libPath -PathType Directory)) {
                throw "scripts/lib directory not found at: $libPath"
            }
        }
        else {
            # Fallback to manual validation
            if (-not ($libPath -and -not [string]::IsNullOrWhiteSpace($libPath) -and (Test-Path -LiteralPath $libPath))) {
                throw "scripts/lib directory not found at: $libPath"
            }
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
        [ValidateNotNullOrEmpty()]
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
    
    # Search for module in subdirectories first, then root
    # Define subdirectory mapping based on organization
    $subdirectoryMap = @{
        'ModuleImport'            = $null  # Stays in root
        'ExitCodes'               = 'core'
        'Logging'                 = 'core'
        'Platform'                = 'core'
        'FragmentConfig'          = 'fragment'
        'FragmentErrorHandling'   = 'fragment'
        'FragmentIdempotency'     = 'fragment'
        'FragmentLoading'         = 'fragment'
        'PathResolution'          = 'path'
        'PathUtilities'           = 'path'
        'PathValidation'          = 'path'
        'FileContent'             = 'file'
        'FileFiltering'           = 'file'
        'FileSystem'              = 'file'
        'CodeMetrics'             = 'metrics'
        'CodeQualityScore'        = 'metrics'
        'MetricsHistory'          = 'metrics'
        'MetricsSnapshot'         = 'metrics'
        'MetricsTrendAnalysis'    = 'metrics'
        'PerformanceAggregation'  = 'performance'
        'PerformanceMeasurement'  = 'performance'
        'PerformanceRegression'   = 'performance'
        'AstParsing'              = 'code-analysis'
        'CodeSimilarityDetection' = 'code-analysis'
        'CommentHelp'             = 'code-analysis'
        'TestCoverage'            = 'code-analysis'
        'Cache'                   = 'utilities'
        'Collections'             = 'utilities'
        'Command'                 = 'utilities'
        'DataFile'                = 'utilities'
        'JsonUtilities'           = 'utilities'
        'RegexUtilities'          = 'utilities'
        'StringSimilarity'        = 'utilities'
        'Module'                  = 'runtime'
        'NodeJs'                  = 'runtime'
        'PowerShellDetection'     = 'runtime'
        'Python'                  = 'runtime'
        'ScoopDetection'          = 'runtime'
        'Parallel'                = 'parallel'
    }
    
    # Remove .psm1 extension for lookup if present
    $moduleNameForLookup = if ($ModuleName.EndsWith('.psm1')) {
        $ModuleName.Substring(0, $ModuleName.Length - 5)
    }
    else {
        $ModuleName
    }
    
    # Determine module path based on subdirectory mapping
    $modulePath = $null
    if ($subdirectoryMap.ContainsKey($moduleNameForLookup)) {
        $subdir = $subdirectoryMap[$moduleNameForLookup]
        if ($null -eq $subdir) {
            # Module stays in root (e.g., ModuleImport)
            $modulePath = Join-Path $libPath $moduleFileName
        }
        else {
            # Module is in a subdirectory
            $modulePath = Join-Path $libPath $subdir $moduleFileName
        }
    }
    else {
        # Fallback: try root first, then search all subdirectories
        $modulePath = Join-Path $libPath $moduleFileName
        
        # Use Validation module if available for path checking
        $pathValid = if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
            Test-ValidPath -Path $modulePath -PathType File -MustExist:$false
        }
        else {
            $modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath)
        }
        
        if ($pathValid -and -not (Test-Path -LiteralPath $modulePath)) {
            # Search all subdirectories
            $subdirs = @('core', 'fragment', 'path', 'file', 'metrics', 'performance', 'code-analysis', 'utilities', 'runtime', 'parallel')
            foreach ($subdir in $subdirs) {
                $testPath = Join-Path $libPath $subdir $moduleFileName
                $testPathValid = if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
                    Test-ValidPath -Path $testPath -PathType File
                }
                else {
                    $testPath -and -not [string]::IsNullOrWhiteSpace($testPath) -and (Test-Path -LiteralPath $testPath)
                }
                if ($testPathValid) {
                    $modulePath = $testPath
                    break
                }
            }
        }
    }

    # Get ErrorAction preference from common parameters
    $errorActionPreference = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
        $PSBoundParameters['ErrorAction']
    }
    else {
        'Stop'
    }

    # Verify module file exists before attempting import
    # Use Validation module if available, otherwise fall back to manual check
    $moduleExists = if (Get-Command Test-ValidPath -ErrorAction SilentlyContinue) {
        Test-ValidPath -Path $modulePath -PathType File
    }
    else {
        $modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)
    }
    
    if (-not $moduleExists) {
        if ($Required) {
            throw "Module '$ModuleName' not found at: $modulePath"
        }
        if ($errorActionPreference -ne 'SilentlyContinue') {
            $debugLevel = 0
            if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                if ($debugLevel -ge 1) {
                    if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                        Write-StructuredWarning -Message "Module not found" -OperationName 'module-import.load' -Context @{
                            # Technical context
                            module_name           = $ModuleName
                            module_path           = $modulePath
                            lib_path              = $libPath
                            script_path           = $ScriptPath
                            # Operation context
                            required              = $false
                            disable_name_checking = $DisableNameChecking
                            error_action          = $errorActionPreference
                            # Invocation context
                            function_name         = 'Import-LibModule'
                        } -Code 'ModuleNotFound'
                    }
                    else {
                        Write-Warning "[module-import.load] Module '$ModuleName' not found at: $modulePath"
                    }
                }
                # Level 3: Log detailed module not found information
                if ($debugLevel -ge 3) {
                    Write-Verbose "[module-import.load] Module not found details - ModuleName: $ModuleName, ModulePath: $modulePath, LibPath: $libPath, ScriptPath: $ScriptPath, Required: $false"
                }
            }
            else {
                # Always log warnings even if debug is off
                if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                    Write-StructuredWarning -Message "Module not found" -OperationName 'module-import.load' -Context @{
                        module_name           = $ModuleName
                        module_path           = $modulePath
                        lib_path              = $libPath
                        script_path           = $ScriptPath
                        required              = $false
                        disable_name_checking = $DisableNameChecking
                        error_action          = $errorActionPreference
                        function_name         = 'Import-LibModule'
                    } -Code 'ModuleNotFound'
                }
                else {
                    Write-Warning "[module-import.load] Module '$ModuleName' not found at: $modulePath"
                }
            }
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

    # Get ErrorAction preference using ErrorHandling module if available
    if (Get-Command Get-ErrorActionPreference -ErrorAction SilentlyContinue) {
        $errorActionPreference = Get-ErrorActionPreference -PSBoundParameters $PSBoundParameters -Default 'Stop'
    }
    else {
        # Fallback to manual extraction
        $errorActionPreference = if ($PSBoundParameters.ContainsKey('ErrorAction')) {
            $PSBoundParameters['ErrorAction']
        }
        else {
            'Stop'
        }
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
                    # ExitCodes/Exit-WithCode not available yet; surface a terminating error
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        if ($debugLevel -ge 1) {
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'module-import.script-path' -Context @{
                                    # Technical context
                                    script_path   = $ScriptPath
                                    # Operation context
                                    exit_on_error = $true
                                    # Error context
                                    error_message = $errorMessage
                                    # Invocation context
                                    function_name = 'Import-LibModule'
                                }
                            }
                            else {
                                Write-Error $errorMessage -ErrorAction Stop
                            }
                        }
                        # Level 3: Log detailed error information
                        if ($debugLevel -ge 3) {
                            Write-Host "  [module-import.script-path] Script path error details - ScriptPath: $ScriptPath, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                        }
                    }
                    else {
                        # Always log critical errors even if debug is off
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'module-import.script-path' -Context @{
                                script_path   = $ScriptPath
                                exit_on_error = $true
                                error_message = $errorMessage
                                function_name = 'Import-LibModule'
                            }
                        }
                        else {
                            Write-Error $errorMessage -ErrorAction Stop
                        }
                    }
                }
            }
            throw $errorMessage
        }
    }

    # Resolve script path to absolute
    try {
        if ($ScriptPath -and -not [string]::IsNullOrWhiteSpace($ScriptPath)) {
            if (Test-Path -LiteralPath $ScriptPath) {
                $ScriptPath = (Resolve-Path $ScriptPath).Path
            }
            else {
                # Script doesn't exist, but parent directory might
                $parentDir = Split-Path -Parent $ScriptPath
                if ($parentDir -and -not [string]::IsNullOrWhiteSpace($parentDir) -and (Test-Path -LiteralPath $parentDir)) {
                    $parentDir = (Resolve-Path $parentDir).Path
                    $ScriptPath = Join-Path $parentDir (Split-Path -Leaf $ScriptPath)
                }
                # If we couldn't resolve, keep the original ScriptPath (it might be valid for Get-RepoRoot)
            }
        }
        
        # Ensure ScriptPath is not null or empty after resolution
        if (-not $ScriptPath -or [string]::IsNullOrWhiteSpace($ScriptPath)) {
            throw "ScriptPath cannot be null or empty after resolution"
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
                # ExitCodes/Exit-WithCode not available yet; surface a terminating error
                $debugLevel = 0
                if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                    if ($debugLevel -ge 1) {
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'module-import.script-path-resolve' -Context @{
                                # Technical context
                                script_path   = $ScriptPath
                                # Operation context
                                exit_on_error = $true
                                # Error context
                                error_message = $errorMessage
                                # Invocation context
                                function_name = 'Import-LibModule'
                            }
                        }
                        else {
                            Write-Error $errorMessage -ErrorAction Stop
                        }
                    }
                    # Level 3: Log detailed error information
                    if ($debugLevel -ge 3) {
                        Write-Verbose "[module-import.script-path-resolve] Script path resolve error details - ScriptPath: $ScriptPath, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)"
                    }
                }
                else {
                    # Always log critical errors even if debug is off
                    if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                        Write-StructuredError -ErrorRecord $_ -OperationName 'module-import.script-path-resolve' -Context @{
                            script_path   = $ScriptPath
                            exit_on_error = $true
                            error_message = $errorMessage
                            function_name = 'Import-LibModule'
                        }
                    }
                    else {
                        Write-Error $errorMessage -ErrorAction Stop
                    }
                }
            }
        }
        throw $errorMessage
    }

    # Get lib path (always required)
    $libPath = $null
    try {
        # Get-LibPath requires ScriptPath to be a valid path or at least have a valid parent
        if (-not $ScriptPath -or [string]::IsNullOrWhiteSpace($ScriptPath)) {
            throw "ScriptPath is required to resolve lib path"
        }
        # Ensure ScriptPath is a string before calling Get-LibPath
        if ($ScriptPath -isnot [string]) {
            $ScriptPath = [string]$ScriptPath
        }
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
                # ExitCodes/Exit-WithCode not available yet; surface a terminating error
                if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                    Write-StructuredError -ErrorRecord $_ -OperationName 'module-import.lib-path' -Context @{
                        script_path   = $ScriptPath
                        exit_on_error = $true
                    }
                }
                Write-Error $errorMessage -ErrorAction Stop
            }
        }
        throw $errorMessage
    }

    # Import requested modules
    $importedModules = @()
    if ($ImportModules.Count -gt 0) {
        try {
            # Ensure ScriptPath is a valid string before passing to Import-LibModules
            if (-not $ScriptPath -or [string]::IsNullOrWhiteSpace($ScriptPath)) {
                throw "ScriptPath cannot be null or empty when importing modules"
            }
            if ($ScriptPath -isnot [string]) {
                $ScriptPath = [string]$ScriptPath
            }
            
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
                    # ExitCodes/Exit-WithCode not available yet; surface a terminating error
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        if ($debugLevel -ge 1) {
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'module-import.import-modules' -Context @{
                                    # Technical context
                                    script_path           = $ScriptPath
                                    module_names          = $ImportModules
                                    module_count          = if ($ImportModules) { $ImportModules.Count } else { 0 }
                                    # Operation context
                                    exit_on_error         = $true
                                    disable_name_checking = $DisableNameChecking
                                    required              = $Required
                                    # Error context
                                    error_message         = $errorMessage
                                    # Invocation context
                                    function_name         = 'Import-LibModules'
                                }
                            }
                            else {
                                Write-Error $errorMessage -ErrorAction Stop
                            }
                        }
                        # Level 3: Log detailed error information
                        if ($debugLevel -ge 3) {
                            Write-Host "  [module-import.import-modules] Import modules error details - ScriptPath: $ScriptPath, ModuleNames: $($ImportModules -join ', '), Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                        }
                    }
                    else {
                        # Always log critical errors even if debug is off
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'module-import.import-modules' -Context @{
                                script_path           = $ScriptPath
                                module_names          = $ImportModules
                                module_count          = if ($ImportModules) { $ImportModules.Count } else { 0 }
                                exit_on_error         = $true
                                disable_name_checking = $DisableNameChecking
                                required              = $Required
                                error_message         = $errorMessage
                                function_name         = 'Import-LibModules'
                            }
                        }
                        else {
                            Write-Error $errorMessage -ErrorAction Stop
                        }
                    }
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
                # Get-RepoRootSafe has ExitOnError as a switch parameter
                # Pass parameters directly instead of using splatting to avoid parameter binding issues
                if ($ExitOnError) {
                    $repoRoot = Get-RepoRootSafe -ScriptPath $ScriptPath -ExitOnError
                }
                else {
                    $repoRoot = Get-RepoRootSafe -ScriptPath $ScriptPath
                }
            }
            elseif (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                # Ensure ScriptPath is a valid string
                if (-not $ScriptPath -or [string]::IsNullOrWhiteSpace($ScriptPath)) {
                    throw "ScriptPath cannot be null or empty when calling Get-RepoRoot"
                }
                if ($ScriptPath -isnot [string]) {
                    $ScriptPath = [string]$ScriptPath
                }
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
                    # ExitCodes/Exit-WithCode not available yet; surface a terminating error
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        if ($debugLevel -ge 1) {
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'module-import.repo-root' -Context @{
                                    # Technical context
                                    script_path   = $ScriptPath
                                    # Operation context
                                    exit_on_error = $true
                                    get_repo_root = $GetRepoRoot
                                    # Error context
                                    error_message = $errorMessage
                                    # Invocation context
                                    function_name = 'Import-LibModule'
                                }
                            }
                            else {
                                Write-Error $errorMessage -ErrorAction Stop
                            }
                        }
                        # Level 3: Log detailed error information
                        if ($debugLevel -ge 3) {
                            Write-Host "  [module-import.repo-root] Repo root error details - ScriptPath: $ScriptPath, GetRepoRoot: $GetRepoRoot, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                        }
                    }
                    else {
                        # Always log critical errors even if debug is off
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'module-import.repo-root' -Context @{
                                script_path   = $ScriptPath
                                exit_on_error = $true
                                get_repo_root = $GetRepoRoot
                                error_message = $errorMessage
                                function_name = 'Import-LibModule'
                            }
                        }
                        else {
                            Write-Error $errorMessage -ErrorAction Stop
                        }
                    }
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
                    # Pass ExitOnError switch correctly
                    if ($ExitOnError) {
                        $repoRoot = Get-RepoRootSafe -ScriptPath $ScriptPath -ExitOnError
                    }
                    else {
                        $repoRoot = Get-RepoRootSafe -ScriptPath $ScriptPath
                    }
                }
                elseif (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    # Ensure ScriptPath is a valid string
                    if (-not $ScriptPath -or [string]::IsNullOrWhiteSpace($ScriptPath)) {
                        throw "ScriptPath cannot be null or empty when calling Get-RepoRoot"
                    }
                    if ($ScriptPath -isnot [string]) {
                        $ScriptPath = [string]$ScriptPath
                    }
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
                    # ExitCodes/Exit-WithCode not available yet; surface a terminating error
                    $debugLevel = 0
                    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
                        if ($debugLevel -ge 1) {
                            if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                                Write-StructuredError -ErrorRecord $_ -OperationName 'module-import.profile-dir' -Context @{
                                    # Technical context
                                    script_path     = $ScriptPath
                                    repo_root       = $repoRoot
                                    # Operation context
                                    exit_on_error   = $true
                                    get_profile_dir = $GetProfileDir
                                    # Error context
                                    error_message   = $errorMessage
                                    # Invocation context
                                    function_name   = 'Import-LibModule'
                                }
                            }
                            else {
                                Write-Error $errorMessage -ErrorAction Stop
                            }
                        }
                        # Level 3: Log detailed error information
                        if ($debugLevel -ge 3) {
                            Write-Host "  [module-import.profile-dir] Profile directory error details - ScriptPath: $ScriptPath, RepoRoot: $repoRoot, GetProfileDir: $GetProfileDir, Exception: $($_.Exception.GetType().FullName), Message: $($_.Exception.Message), Stack: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
                        }
                    }
                    else {
                        # Always log critical errors even if debug is off
                        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
                            Write-StructuredError -ErrorRecord $_ -OperationName 'module-import.profile-dir' -Context @{
                                script_path     = $ScriptPath
                                repo_root       = $repoRoot
                                exit_on_error   = $true
                                get_profile_dir = $GetProfileDir
                                error_message   = $errorMessage
                                function_name   = 'Import-LibModule'
                            }
                        }
                        else {
                            Write-Error $errorMessage -ErrorAction Stop
                        }
                    }
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

