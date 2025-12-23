# ===============================================
# ModuleLoading.ps1
# Standardized module loading system for fragments
# ===============================================

<#
.SYNOPSIS
    Loads a fragment module with comprehensive validation, caching, and error handling.

.DESCRIPTION
    Provides a standardized way to load fragment modules with:
    - Path validation and caching (uses existing Test-ModulePath)
    - Dependency checking
    - Error handling with context
    - Retry logic for transient failures
    - Performance optimization

.PARAMETER FragmentRoot
    Root directory of fragments (usually $PSScriptRoot).

.PARAMETER ModulePath
    Array of path segments to the module file (e.g., @('dev-tools-modules', 'build', 'build-tools.ps1')).

.PARAMETER Context
    Context string for error messages (e.g., "Fragment: build-tools").

.PARAMETER Required
    If specified, failure to load will throw an error. Otherwise, returns $false.

.PARAMETER Dependencies
    Array of module names that must be loaded before this module.

.PARAMETER RetryCount
    Number of retry attempts for transient failures (default: 0).

.PARAMETER CacheResults
    If specified, uses cached path existence checks for performance (default: $true).

.OUTPUTS
    System.Boolean. $true if module loaded successfully, $false otherwise.

.EXAMPLE
    $success = Import-FragmentModule -FragmentRoot $PSScriptRoot `
        -ModulePath @('dev-tools-modules', 'build', 'build-tools.ps1') `
        -Context "Fragment: build-tools (build-tools.ps1)"

.EXAMPLE
    $success = Import-FragmentModule -FragmentRoot $PSScriptRoot `
        -ModulePath @('git-modules', 'core', 'git-helpers.ps1') `
        -Context "Fragment: git (git-helpers.ps1)" `
        -Dependencies @('bootstrap', 'env') `
        -Required
#>
function global:Import-FragmentModule {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$FragmentRoot,

        [Parameter(Mandatory)]
        [AllowNull()]
        [string[]]$ModulePath,

        [Parameter(Mandatory)]
        [string]$Context,

        [switch]$Required,

        [string[]]$Dependencies = @(),

        [int]$RetryCount = 0,

        [switch]$CacheResults
    )

    # Default to caching enabled
    if (-not $PSBoundParameters.ContainsKey('CacheResults')) {
        $CacheResults = $true
    }

    # Validate FragmentRoot
    if ([string]::IsNullOrWhiteSpace($FragmentRoot)) {
        $errorMsg = "$Context : FragmentRoot cannot be null or empty"
        if ($Required) {
            throw $errorMsg
        }
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning $errorMsg
        }
        return $false
    }

    # Build full path
    $moduleFilePath = $null
    try {
        $currentPath = $FragmentRoot
        foreach ($segment in $ModulePath) {
            if ([string]::IsNullOrWhiteSpace($segment)) {
                $errorMsg = "$Context : Module path segment cannot be null or empty"
                if ($Required) {
                    throw $errorMsg
                }
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Warning $errorMsg
                }
                return $false
            }

            $currentPath = Join-Path $currentPath $segment

            # Validate each path segment exists (for directories)
            if ($segment -ne $ModulePath[-1]) {
                # Check directory exists
                $dirExists = if ($CacheResults -and (Get-Command Test-ModulePath -ErrorAction SilentlyContinue)) {
                    Test-ModulePath -Path $currentPath
                }
                else {
                    if ($currentPath -and -not [string]::IsNullOrWhiteSpace($currentPath)) {
                        Test-Path -LiteralPath $currentPath -PathType Container -ErrorAction SilentlyContinue
                    }
                    else {
                        $false
                    }
                }

                if (-not $dirExists) {
                    $errorMsg = "$Context : Directory not found: $currentPath"
                    if ($Required) {
                        throw $errorMsg
                    }
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Warning $errorMsg
                    }
                    return $false
                }
            }
        }

        $moduleFilePath = $currentPath

        # Validate final file exists using cached path check
        $fileExists = if ($CacheResults -and (Get-Command Test-ModulePath -ErrorAction SilentlyContinue)) {
            Test-ModulePath -Path $moduleFilePath
        }
        else {
            if ($moduleFilePath -and -not [string]::IsNullOrWhiteSpace($moduleFilePath)) {
                Test-Path -LiteralPath $moduleFilePath -PathType Leaf -ErrorAction SilentlyContinue
            }
            else {
                $false
            }
        }

        if (-not $fileExists) {
            $errorMsg = "$Context : Module file not found: $moduleFilePath"
            if ($Required) {
                throw $errorMsg
            }
            if ($env:PS_PROFILE_DEBUG) {
                Write-Warning $errorMsg
            }
            return $false
        }
    }
    catch {
        $errorMsg = "$Context : Failed to build module path: $($_.Exception.Message)"
        if ($Required) {
            throw $errorMsg
        }
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning $errorMsg
        }
        return $false
    }

    # Check dependencies
    if ($Dependencies.Count -gt 0) {
        $missingDeps = @()
        foreach ($dep in $Dependencies) {
            # Check if dependency module/function is loaded
            $depLoaded = $false

            # Check for function (common pattern)
            if (Test-Path "Function:\$dep" -ErrorAction SilentlyContinue) {
                $depLoaded = $true
            }
            elseif (Test-Path "Function:\global:$dep" -ErrorAction SilentlyContinue) {
                $depLoaded = $true
            }
            # Check for module
            elseif (Get-Module -Name $dep -ErrorAction SilentlyContinue) {
                $depLoaded = $true
            }
            # Check for command (could be alias, function, or cmdlet)
            elseif (Get-Command -Name $dep -ErrorAction SilentlyContinue) {
                $depLoaded = $true
            }

            if (-not $depLoaded) {
                $missingDeps += $dep
            }
        }

        if ($missingDeps.Count -gt 0) {
            $errorMsg = "$Context : Missing dependencies: $($missingDeps -join ', ')"
            if ($Required) {
                throw $errorMsg
            }
            if ($env:PS_PROFILE_DEBUG) {
                Write-Warning $errorMsg
            }
            return $false
        }
    }

    # Validate file is readable PowerShell script
    try {
        $fileInfo = Get-Item -Path $moduleFilePath -ErrorAction Stop
        if (-not $fileInfo) {
            throw "Unable to get file information"
        }

        # Basic validation: check file extension
        if ($fileInfo.Extension -ne '.ps1') {
            $errorMsg = "$Context : Invalid file type: $($fileInfo.Extension). Expected .ps1"
            if ($Required) {
                throw $errorMsg
            }
            if ($env:PS_PROFILE_DEBUG) {
                Write-Warning $errorMsg
            }
            return $false
        }

        # Optional: Validate PowerShell syntax (can be expensive, only in debug mode)
        if ($env:PS_PROFILE_DEBUG_SYNTAX_CHECK) {
            $parseErrors = $null
            $null = [System.Management.Automation.PSParser]::Tokenize(
                (Get-Content -Path $moduleFilePath -Raw),
                [ref]$parseErrors
            )
            if ($parseErrors.Count -gt 0) {
                $errorMsg = "$Context : PowerShell syntax errors in $moduleFilePath : $($parseErrors[0].Message)"
                if ($Required) {
                    throw $errorMsg
                }
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Warning $errorMsg
                }
                return $false
            }
        }
    }
    catch {
        $errorMsg = "$Context : Cannot access module file '$moduleFilePath': $($_.Exception.Message)"
        if ($Required) {
            throw $errorMsg
        }
        if ($env:PS_PROFILE_DEBUG) {
            Write-Warning $errorMsg
        }
        return $false
    }

    # Load module with retry logic
    $attempt = 0
    $lastError = $null

    do {
        $attempt++
        try {
            # Use Invoke-FragmentSafely if available for better error handling
            if (Get-Command Invoke-FragmentSafely -ErrorAction SilentlyContinue) {
                $success = Invoke-FragmentSafely -FragmentName $Context -FragmentPath $moduleFilePath
                if ($success) {
                    return $true
                }
                else {
                    $lastError = "Invoke-FragmentSafely returned false"
                }
            }
            else {
                # Fallback: direct dot-sourcing
                # Dot-source the module file
                . $moduleFilePath
                return $true
            }
        }
        catch {
            $lastError = $_

            # Don't retry on syntax errors or missing file errors
            $errorId = $_.FullyQualifiedErrorId
            if ($errorId -like '*ParseError*' -or
                $errorId -like '*FileNotFound*' -or
                $errorId -like '*PathNotFound*') {
                break
            }

            if ($attempt -le $RetryCount) {
                $delay = [math]::Pow(2, $attempt - 1) * 100  # Exponential backoff: 100ms, 200ms, 400ms
                if ($env:PS_PROFILE_DEBUG) {
                    Write-Verbose "$Context : Retry attempt $attempt/$RetryCount after ${delay}ms delay"
                }
                Start-Sleep -Milliseconds $delay
            }
        }
    } while ($attempt -le $RetryCount)

    # Final error handling
    $errorMsg = "$Context : Failed to load module '$moduleFilePath'"
    if ($lastError) {
        $errorMsg += ": $($lastError.Exception.Message)"
    }
    if ($attempt -gt 1) {
        $errorMsg += " (after $attempt attempts)"
    }

    if ($Required) {
        throw $errorMsg
    }

    # Use standard error handling
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        if ($lastError) {
            Write-ProfileError -ErrorRecord $lastError -Context $Context -Category 'Fragment'
        }
        else {
            Write-ProfileError -Message $errorMsg -Context $Context -Category 'Fragment'
        }
    }
    elseif ($env:PS_PROFILE_DEBUG) {
        Write-Warning $errorMsg
    }

    return $false
}

<#
.SYNOPSIS
    Loads multiple fragment modules with batch optimization.

.DESCRIPTION
    Loads multiple modules efficiently, validating all paths first,
    then loading sequentially (respecting dependencies if specified).

.PARAMETER FragmentRoot
    Root directory of fragments.

.PARAMETER Modules
    Array of hashtables, each containing ModulePath, Context, and optional Dependencies.

.PARAMETER StopOnError
    If specified, stops loading on first error.

.EXAMPLE
    Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules @(
        @{ ModulePath = @('dev-tools-modules', 'build', 'build-tools.ps1'); Context = 'build-tools' },
        @{ ModulePath = @('dev-tools-modules', 'build', 'testing-frameworks.ps1'); Context = 'testing' }
    )
#>
function global:Import-FragmentModules {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$FragmentRoot,

        [Parameter(Mandatory)]
        [AllowNull()]
        [hashtable[]]$Modules,

        [switch]$StopOnError
    )

    $results = @{}
    $failed = @()

    # Phase 1: Validate all paths first (fast validation)
    $validModules = @()
    foreach ($module in $Modules) {
        $modulePath = $module.ModulePath
        $context = $module.Context

        if (-not $modulePath -or -not $context) {
            $errorMsg = "Module definition missing ModulePath or Context"
            $failed += $context
            $results[$context] = @{ Success = $false; Error = $errorMsg }
            if ($StopOnError) {
                break
            }
            continue
        }

        try {
            $currentPath = $FragmentRoot
            foreach ($segment in $modulePath) {
                if ([string]::IsNullOrWhiteSpace($segment)) {
                    throw "Empty path segment in module path"
                }
                $currentPath = Join-Path $currentPath $segment
            }

            # Use cached path check if available
            $pathExists = if (Get-Command Test-ModulePath -ErrorAction SilentlyContinue) {
                Test-ModulePath -Path $currentPath
            }
            else {
                if ($currentPath -and -not [string]::IsNullOrWhiteSpace($currentPath)) {
                    Test-Path -LiteralPath $currentPath -ErrorAction SilentlyContinue
                }
                else {
                    $false
                }
            }

            if ($pathExists) {
                $validModules += @{
                    ModulePath   = $modulePath
                    Context      = $context
                    FullPath     = $currentPath
                    Dependencies = if ($module.Dependencies) { $module.Dependencies } else { @() }
                }
            }
            else {
                $failed += $context
                $results[$context] = @{ Success = $false; Error = "File not found: $currentPath" }
                if ($StopOnError) {
                    break
                }
            }
        }
        catch {
            $failed += $context
            $results[$context] = @{ Success = $false; Error = $_.Exception.Message }
            if ($StopOnError) {
                break
            }
        }
    }

    # Phase 2: Load valid modules
    foreach ($module in $validModules) {
        if ($StopOnError -and $failed.Count -gt 0) {
            break
        }

        $success = Import-FragmentModule `
            -FragmentRoot $FragmentRoot `
            -ModulePath $module.ModulePath `
            -Context $module.Context `
            -Dependencies $module.Dependencies `
            -CacheResults

        $results[$module.Context] = @{ Success = $success }
        if (-not $success) {
            $failed += $module.Context
            if ($StopOnError) {
                break
            }
        }
    }

    return @{
        Results      = $results
        Failed       = $failed
        SuccessCount = ($results.Values | Where-Object { $_.Success }).Count
        FailureCount = $failed.Count
    }
}

<#
.SYNOPSIS
    Validates that a module path exists and is accessible.

.DESCRIPTION
    Checks if a module path is valid without loading the module.
    Useful for dependency checking and validation.
    Uses the existing Test-ModulePath function when a full path is provided,
    or builds the path from segments when FragmentRoot and ModulePath are provided.

.PARAMETER FragmentRoot
    Root directory of fragments.

.PARAMETER ModulePath
    Array of path segments to the module file.

.PARAMETER Path
    Full path to the module file (alternative to FragmentRoot + ModulePath).

.OUTPUTS
    System.Boolean. $true if path is valid, $false otherwise.

.EXAMPLE
    if (Test-FragmentModulePath -FragmentRoot $PSScriptRoot -ModulePath @('dev-tools-modules', 'build', 'build-tools.ps1')) {
        # Module exists
    }

.EXAMPLE
    if (Test-FragmentModulePath -Path $modulePath) {
        # Module exists (uses existing Test-ModulePath)
    }
#>
function global:Test-FragmentModulePath {
    [CmdletBinding(DefaultParameterSetName = 'ByPath')]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory, ParameterSetName = 'BySegments')]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$FragmentRoot,

        [Parameter(Mandatory, ParameterSetName = 'BySegments')]
        [AllowNull()]
        [string[]]$ModulePath,

        [Parameter(Mandatory, ParameterSetName = 'ByPath')]
        [AllowNull()]
        [AllowEmptyString()]
        [string]$Path
    )

    # If Path is provided, use existing Test-ModulePath
    if ($PSCmdlet.ParameterSetName -eq 'ByPath') {
        if (Get-Command Test-ModulePath -ErrorAction SilentlyContinue) {
            return Test-ModulePath -Path $Path
        }
        else {
            if ($Path -and -not [string]::IsNullOrWhiteSpace($Path)) {
                return Test-Path -LiteralPath $Path -ErrorAction SilentlyContinue
            }
            return $false
        }
    }

    # Build path from segments
    if ([string]::IsNullOrWhiteSpace($FragmentRoot)) {
        return $false
    }

    try {
        $currentPath = $FragmentRoot
        foreach ($segment in $ModulePath) {
            if ([string]::IsNullOrWhiteSpace($segment)) {
                return $false
            }

            $currentPath = Join-Path $currentPath $segment

            # Check if this is the final segment (file)
            if ($segment -eq $ModulePath[-1]) {
                # Use cached path check if available
                if (Get-Command Test-ModulePath -ErrorAction SilentlyContinue) {
                    return Test-ModulePath -Path $currentPath
                }
                else {
                    return Test-Path -LiteralPath $currentPath -PathType Leaf -ErrorAction SilentlyContinue
                }
            }
            else {
                # Check directory exists
                $dirExists = if (Get-Command Test-ModulePath -ErrorAction SilentlyContinue) {
                    Test-ModulePath -Path $currentPath
                }
                else {
                    if ($currentPath -and -not [string]::IsNullOrWhiteSpace($currentPath)) {
                        Test-Path -LiteralPath $currentPath -PathType Container -ErrorAction SilentlyContinue
                    }
                    else {
                        $false
                    }
                }

                if (-not $dirExists) {
                    return $false
                }
            }
        }

        return $false
    }
    catch {
        return $false
    }
}

