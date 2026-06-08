# Module Loading Standard

Standard module loading for profile fragments via `Import-FragmentModule` and `Import-FragmentModules`.

**Implementation:** `profile.d/bootstrap/ModuleLoading.ps1` (loaded by bootstrap). All fragments should use these functions instead of ad-hoc dot-sourcing.

## Background: Patterns This Replaces

### 1. Repetitive Path Validation

**Legacy pattern** (do not use in new code):

```powershell
$devToolsModulesDir = Join-Path $PSScriptRoot 'dev-tools-modules'
if ($devToolsModulesDir -and -not [string]::IsNullOrWhiteSpace($devToolsModulesDir) -and (Test-Path -LiteralPath $devToolsModulesDir)) {
    $buildDir = Join-Path $devToolsModulesDir 'build'
    if ($buildDir -and -not [string]::IsNullOrWhiteSpace($buildDir) -and (Test-Path -LiteralPath $buildDir)) {
        $modulePath = Join-Path $buildDir 'build-tools.ps1'
        if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
            try {
                . $modulePath
            }
            catch {
                # Error handling
            }
        }
    }
}
```

**Issues**:

- Repetitive null/whitespace checks
- Multiple Test-Path calls (performance)
- No path caching
- Hard to read and maintain
- Inconsistent error handling

### 2. Inconsistent Error Handling

- Some fragments use `Write-ProfileError`
- Some use `Write-Warning`
- Some fail silently
- Error messages lack context

### 3. No Dependency Validation

- Modules can load before dependencies
- No validation that required modules exist
- Circular dependency detection missing

### 4. Performance Issues

- Multiple `Test-Path` calls for same paths
- No caching of path existence
- Eager loading of all modules

---

## Standard Module Loading System

### Core Functions

**Location**: `profile.d/bootstrap/ModuleLoading.ps1` — loaded by bootstrap and available to all fragments. Use `Import-FragmentModule` and `Import-FragmentModules` instead of ad-hoc dot-sourcing with nested `Test-Path` checks.

#### 1. Import-FragmentModule

**Location**: `profile.d/bootstrap/ModuleLoading.ps1`

**Purpose**: Robust, cached, dependency-aware module loading

```powershell
<#
.SYNOPSIS
    Loads a fragment module with comprehensive validation, caching, and error handling.

.DESCRIPTION
    Provides a standardized way to load fragment modules with:
    - Path validation and caching
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
    If specified, caches path existence checks for performance.

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
function Import-FragmentModule {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentRoot,

        [Parameter(Mandatory)]
        [string[]]$ModulePath,

        [Parameter(Mandatory)]
        [string]$Context,

        [switch]$Required,

        [string[]]$Dependencies = @(),

        [int]$RetryCount = 0,

        [switch]$CacheResults
    )

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

    # Check cache if enabled
    $cacheKey = $null
    if ($CacheResults -and (Get-Command Get-CachedPathExists -ErrorAction SilentlyContinue)) {
        $cacheKey = ($FragmentRoot, $ModulePath) -join '|'
        $cachedResult = Get-CachedPathExists -Path $cacheKey
        if ($null -ne $cachedResult) {
            if (-not $cachedResult) {
                return $false
            }
            # Path exists, continue to load
        }
    }

    # Build full path
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
                if (-not (Test-Path -LiteralPath $currentPath -PathType Container -ErrorAction SilentlyContinue)) {
                    $errorMsg = "$Context : Directory not found: $currentPath"
                    if ($Required) {
                        throw $errorMsg
                    }
                    if ($env:PS_PROFILE_DEBUG) {
                        Write-Warning $errorMsg
                    }

                    # Cache negative result
                    if ($CacheResults -and $cacheKey) {
                        Set-CachedPathExists -Path $cacheKey -Exists $false
                    }
                    return $false
                }
            }
        }

        $moduleFilePath = $currentPath

        # Validate final file exists
        if (-not (Test-Path -LiteralPath $moduleFilePath -PathType Leaf -ErrorAction SilentlyContinue)) {
            $errorMsg = "$Context : Module file not found: $moduleFilePath"
            if ($Required) {
                throw $errorMsg
            }
            if ($env:PS_PROFILE_DEBUG) {
                Write-Warning $errorMsg
            }

            # Cache negative result
            if ($CacheResults -and $cacheKey) {
                Set-CachedPathExists -Path $cacheKey -Exists $false
            }
            return $false
        }

        # Cache positive result
        if ($CacheResults -and $cacheKey) {
            Set-CachedPathExists -Path $cacheKey -Exists $true
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
                $null = . $moduleFilePath
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
```

#### 2. Import-FragmentModules (Batch Loading)

**Purpose**: Load multiple modules efficiently

```powershell
<#
.SYNOPSIS
    Loads multiple fragment modules with batch optimization.

.DESCRIPTION
    Loads multiple modules efficiently, validating all paths first,
    then loading in parallel where possible (or sequentially if dependencies exist).

.PARAMETER FragmentRoot
    Root directory of fragments.

.PARAMETER Modules
    Array of hashtables, each containing ModulePath and Context.

.PARAMETER StopOnError
    If specified, stops loading on first error.

.EXAMPLE
    Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules @(
        @{ ModulePath = @('dev-tools-modules', 'build', 'build-tools.ps1'); Context = 'build-tools' },
        @{ ModulePath = @('dev-tools-modules', 'build', 'testing-frameworks.ps1'); Context = 'testing' }
    )
#>
function Import-FragmentModules {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentRoot,

        [Parameter(Mandatory)]
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

        try {
            $currentPath = $FragmentRoot
            foreach ($segment in $modulePath) {
                $currentPath = Join-Path $currentPath $segment
            }

            if (Test-Path -LiteralPath $currentPath -ErrorAction SilentlyContinue) {
                $validModules += @{
                    ModulePath = $modulePath
                    Context = $context
                    FullPath = $currentPath
                }
            }
            else {
                $failed += $context
                $results[$context] = @{ Success = $false; Error = "File not found: $currentPath" }
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
        Results = $results
        Failed = $failed
        SuccessCount = ($results.Values | Where-Object { $_.Success }).Count
        FailureCount = $failed.Count
    }
}
```

#### 3. Test-ModulePath (Validation Helper)

**Purpose**: Validate module path without loading

```powershell
<#
.SYNOPSIS
    Validates that a module path exists and is accessible.

.DESCRIPTION
    Checks if a module path is valid without loading the module.
    Useful for dependency checking and validation.

.PARAMETER FragmentRoot
    Root directory of fragments.

.PARAMETER ModulePath
    Array of path segments to the module file.

.OUTPUTS
    System.Boolean. $true if path is valid, $false otherwise.

.EXAMPLE
    if (Test-ModulePath -FragmentRoot $PSScriptRoot -ModulePath @('dev-tools-modules', 'build', 'build-tools.ps1')) {
        # Module exists
    }
#>
function Test-ModulePath {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentRoot,

        [Parameter(Mandatory)]
        [string[]]$ModulePath
    )

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
                return (Test-Path -LiteralPath $currentPath -PathType Leaf -ErrorAction SilentlyContinue)
            }
            else {
                # Check directory exists
                if (-not (Test-Path -LiteralPath $currentPath -PathType Container -ErrorAction SilentlyContinue)) {
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
```

---

## Usage Examples

### Simple Module Loading

**Before** (error-prone):

```powershell
try {
    $devToolsModulesDir = Join-Path $PSScriptRoot 'dev-tools-modules'
    if ($devToolsModulesDir -and -not [string]::IsNullOrWhiteSpace($devToolsModulesDir) -and (Test-Path -LiteralPath $devToolsModulesDir)) {
        $buildDir = Join-Path $devToolsModulesDir 'build'
        if ($buildDir -and -not [string]::IsNullOrWhiteSpace($buildDir) -and (Test-Path -LiteralPath $buildDir)) {
            $modulePath = Join-Path $buildDir 'build-tools.ps1'
            if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                try {
                    . $modulePath
                }
                catch {
                    # Error handling
                }
            }
        }
    }
}
catch {
    # Error handling
}
```

**After** (robust):

```powershell
Import-FragmentModule -FragmentRoot $PSScriptRoot `
    -ModulePath @('dev-tools-modules', 'build', 'build-tools.ps1') `
    -Context "Fragment: build-tools (build-tools.ps1)" `
    -CacheResults
```

### Batch Module Loading

**Before**:

```powershell
# Load each module individually with repetitive code
```

**After**:

```powershell
$results = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules @(
    @{ ModulePath = @('dev-tools-modules', 'build', 'build-tools.ps1'); Context = 'build-tools' },
    @{ ModulePath = @('dev-tools-modules', 'build', 'testing-frameworks.ps1'); Context = 'testing' },
    @{ ModulePath = @('cli-modules', 'modern-cli.ps1'); Context = 'modern-cli' }
)

if ($results.FailureCount -gt 0) {
    Write-Warning "Failed to load $($results.FailureCount) modules: $($results.Failed -join ', ')"
}
```

### Module with Dependencies

```powershell
# Load module only if dependencies are available
Import-FragmentModule -FragmentRoot $PSScriptRoot `
    -ModulePath @('git-modules', 'enhanced', 'git-enhanced.ps1') `
    -Context "Fragment: git-enhanced" `
    -Dependencies @('bootstrap', 'env', 'git') `
    -Required
```

### Conditional Module Loading

```powershell
# Only load if path exists (non-critical module)
if (Test-ModulePath -FragmentRoot $PSScriptRoot -ModulePath @('optional-modules', 'experimental.ps1')) {
    Import-FragmentModule -FragmentRoot $PSScriptRoot `
        -ModulePath @('optional-modules', 'experimental.ps1') `
        -Context "Fragment: experimental"
}
```

---

## Migrating Legacy Fragments

Replace nested `Test-Path` + dot-source blocks with:

```powershell
Import-FragmentModule -FragmentRoot $PSScriptRoot `
    -ModulePath @('dev-tools-modules', 'build', 'build-tools.ps1') `
    -Context "Fragment: build-tools (build-tools.ps1)" `
    -CacheResults
```

Use `Import-FragmentModules` when loading many modules from the same fragment. See `tests/integration/bootstrap/module-loading-standard.tests.ps1` for expected behavior.

---

## Benefits

- Path caching and batch validation reduce redundant filesystem checks
- Dependency and retry support with structured error context
- Single API across fragments (~80% less boilerplate than manual dot-sourcing)
- Validation catches path and dependency issues early with detailed error messages

---

## Testing Requirements

### Unit Tests

- Test path validation (valid/invalid paths)
- Test dependency checking (missing/present dependencies)
- Test error handling (various error scenarios)
- Test caching (cache hits/misses)
- Test retry logic (transient failures)

### Integration Tests

- Test module loading in real fragments
- Test batch loading
- Test dependency resolution
- Test error recovery

### Performance Tests

- Measure startup time impact
- Compare with old pattern
- Test cache effectiveness

---

## Migration Checklist

**Status**: ✅ **IMPLEMENTED** - Core system complete and in use.

**Implementation Status**:

- [x] ✅ Core implementation complete - `Import-FragmentModule`, `Import-FragmentModules`, `Test-FragmentModulePath` implemented in `profile.d/bootstrap/ModuleLoading.ps1`
- [x] ✅ Unit tests complete - 38 unit tests + 32 additional tests (70 total) covering all functions
- [x] ✅ Integration tests complete - 12 integration tests verifying real fragment loading
- [x] ✅ Fragments migrated - 6 fragments refactored: `files.ps1`, `containers.ps1`, `git.ps1`, `utilities.ps1`, `system.ps1`, `starship.ps1`
- [x] ✅ Coverage achieved - 85.2% coverage (exceeds 75% target)
- [ ] Performance testing (baseline established, ongoing monitoring)
- [ ] Additional fragments migration (as needed)
- [ ] Code review

**When migrating additional fragments**:

- [ ] Replace manual path building with `Import-FragmentModule` or `Import-FragmentModules`
- [ ] Add appropriate `Context` parameter
- [ ] Add `Dependencies` if module has dependencies
- [ ] Enable `CacheResults` for performance (default: enabled)
- [ ] Remove old error handling code
- [ ] Test module loads correctly
- [ ] Test error handling (missing file, invalid path, etc.)
- [ ] Verify no performance regression
- [ ] Update documentation

---

## Backward Compatibility

During migration, support both patterns:

1. **New modules**: Use `Import-FragmentModule`
2. **Old modules**: Continue working (gradually migrate)
3. **Transition period**: Both patterns work simultaneously

After migration complete:

- Remove old pattern support
- Update all documentation
- Enforce new pattern in linting

---

## Notes

- This solution addresses all identified issues with module loading
- Path caching significantly improves performance
- Dependency checking prevents load-order issues
- Comprehensive error handling improves debugging
- Simple API reduces developer burden
- 100% test coverage required for all new functions
