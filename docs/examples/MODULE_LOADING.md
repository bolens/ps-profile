# Using Standardized Module Loading

This guide demonstrates how to use the standardized module loading system (`Import-FragmentModule` and `Import-FragmentModules`) to load fragment modules with validation, caching, and error handling.

## Overview

The standardized module loading system provides:

- **Path validation and caching** - Uses existing `Test-ModulePath` for performance
- **Dependency checking** - Ensures required modules are loaded first
- **Error handling with context** - Clear error messages with module context
- **Retry logic** - Handles transient failures automatically
- **Performance optimization** - Caches path existence checks

## Basic Usage

### Loading a Single Module

```powershell
# Load a module from a subdirectory
$success = Import-FragmentModule `
    -FragmentRoot $PSScriptRoot `
    -ModulePath @('dev-tools-modules', 'build', 'build-tools.ps1') `
    -Context "Fragment: build-tools (build-tools.ps1)"

if ($success) {
    Write-Verbose "Module loaded successfully"
}
```

### Loading with Dependencies

```powershell
# Load a module that requires other modules to be loaded first
$success = Import-FragmentModule `
    -FragmentRoot $PSScriptRoot `
    -ModulePath @('git-modules', 'core', 'git-helpers.ps1') `
    -Context "Fragment: git (git-helpers.ps1)" `
    -Dependencies @('bootstrap', 'env')

if (-not $success) {
    Write-Warning "Failed to load git-helpers module"
}
```

### Loading with Retry Logic

```powershell
# Load a module with retry logic for transient failures
$success = Import-FragmentModule `
    -FragmentRoot $PSScriptRoot `
    -ModulePath @('container-modules', 'container-helpers.ps1') `
    -Context "Fragment: containers (container-helpers.ps1)" `
    -RetryCount 3

if ($success) {
    Write-Verbose "Container helpers loaded after retries"
}
```

### Required Modules

```powershell
# Load a required module (throws error if it fails)
try {
    Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('core-modules', 'essential.ps1') `
        -Context "Fragment: essential (essential.ps1)" `
        -Required
}
catch {
    Write-Error "Failed to load required module: $_"
}
```

## Batch Loading

### Loading Multiple Modules

```powershell
# Load multiple modules at once with Import-FragmentModules
$modules = @(
    @{
        ModulePath = @('container-modules', 'container-helpers.ps1')
        Context = 'Fragment: 22-containers (container-helpers.ps1)'
    },
    @{
        ModulePath = @('container-modules', 'container-compose.ps1')
        Context = 'Fragment: 22-containers (container-compose.ps1)'
    },
    @{
        ModulePath = @('container-modules', 'container-compose-podman.ps1')
        Context = 'Fragment: 22-containers (container-compose-podman.ps1)'
    }
)

$result = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules

if ($result.SuccessCount -gt 0) {
    Write-Verbose "Loaded $($result.SuccessCount) modules successfully"
}

if ($result.FailureCount -gt 0) {
    Write-Warning "Failed to load $($result.FailureCount) modules"
}
```

### Batch Loading with Error Handling

```powershell
# Load multiple modules with comprehensive error handling
try {
    $modules = @(
        @{
            ModulePath = @('dev-tools-modules', 'build', 'build-tools.ps1')
            Context = 'Fragment: build-tools'
            Dependencies = @('bootstrap', 'env')
        },
        @{
            ModulePath = @('dev-tools-modules', 'build', 'testing-frameworks.ps1')
            Context = 'Fragment: testing-frameworks'
            Dependencies = @('bootstrap', 'env')
        }
    )

    $result = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules

    if ($result.FailureCount -gt 0 -and $env:PS_PROFILE_DEBUG) {
        foreach ($failure in $result.Failures) {
            Write-Warning "Failed to load $($failure.ModulePath -join '/'): $($failure.Error)"
        }
    }
}
catch {
    if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: build-tools" -Category 'Fragment'
    }
    else {
        Write-Warning "Failed to load build tools modules: $($_.Exception.Message)"
    }
}
```

## Real-World Examples

### Example 1: Fragment with Submodules

```powershell
# ===============================================
# containers.ps1
# Container engine helpers (Docker/Podman)
# ===============================================
# Dependencies: bootstrap, env
# Tier: standard

# Load container utility modules using standardized module loading
if (Get-Command Import-FragmentModules -ErrorAction SilentlyContinue) {
    try {
        $modules = @(
            @{
                ModulePath = @('container-modules', 'container-helpers.ps1')
                Context = 'Fragment: containers (container-helpers.ps1)'
            },
            @{
                ModulePath = @('container-modules', 'container-compose.ps1')
                Context = 'Fragment: containers (container-compose.ps1)'
            },
            @{
                ModulePath = @('container-modules', 'container-compose-podman.ps1')
                Context = 'Fragment: containers (container-compose-podman.ps1)'
            }
        )

        $result = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules

        if ($env:PS_PROFILE_DEBUG -and $result.FailureCount -gt 0) {
            Write-Verbose "Loaded $($result.SuccessCount) container modules (failed: $($result.FailureCount))"
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                Write-ProfileError -ErrorRecord $_ -Context "Fragment: containers" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load containers fragment: $($_.Exception.Message)"
            }
        }
    }
}
else {
    # Fallback: manual loading for environments where Import-FragmentModules is not yet available
    # ... fallback code ...
}
```

### Example 2: Conditional Module Loading

```powershell
# Load optional modules based on tool availability
$optionalModules = @(
    @{
        ModulePath = @('dev-tools-modules', 'security', 'security-tools.ps1')
        Context = 'Fragment: security-tools'
    },
    @{
        ModulePath = @('dev-tools-modules', 'api', 'api-tools.ps1')
        Context = 'Fragment: api-tools'
    }
)

$result = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $optionalModules

# Only proceed if at least one module loaded successfully
if ($result.SuccessCount -gt 0) {
    Write-Verbose "Loaded $($result.SuccessCount) optional development tool modules"
}
```

### Example 3: Module with Dependencies

```powershell
# Load a module that depends on other modules
$success = Import-FragmentModule `
    -FragmentRoot $PSScriptRoot `
    -ModulePath @('git-modules', 'integrations', 'git-github.ps1') `
    -Context "Fragment: git-github (git-github.ps1)" `
    -Dependencies @('bootstrap', 'env', 'git') `
    -Required

if ($success) {
    Write-Verbose "Git GitHub integration loaded"
}
```

## Performance Considerations

### Caching

The module loading system uses path caching by default to improve performance:

```powershell
# Caching is enabled by default (CacheResults = $true)
$success = Import-FragmentModule `
    -FragmentRoot $PSScriptRoot `
    -ModulePath @('modules', 'example.ps1') `
    -Context "Fragment: example"

# Disable caching if needed (not recommended)
$success = Import-FragmentModule `
    -FragmentRoot $PSScriptRoot `
    -ModulePath @('modules', 'example.ps1') `
    -Context "Fragment: example" `
    -CacheResults:$false
```

### Lazy Loading

For expensive modules, consider using lazy loading instead:

```powershell
# Register a lazy-loading function instead of loading immediately
Register-LazyFunction -Name 'Enable-ExpensiveModule' -Initializer {
    Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('expensive-modules', 'heavy-tool.ps1') `
        -Context "Fragment: heavy-tool" `
        -Required
} -Alias 'enable-heavy'
```

## Error Handling

### Standard Error Handling Pattern

```powershell
try {
    $success = Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('modules', 'example.ps1') `
        -Context "Fragment: example" `
        -Required

    if (-not $success) {
        throw "Failed to load module"
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: example" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load example module: $($_.Exception.Message)"
        }
    }
}
```

### Graceful Degradation

```powershell
# Try to load with standardized system, fall back to manual loading
if (Get-Command Import-FragmentModule -ErrorAction SilentlyContinue) {
    $success = Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('modules', 'example.ps1') `
        -Context "Fragment: example"

    if (-not $success) {
        # Fallback to manual loading
        $modulePath = Join-Path $PSScriptRoot 'modules' 'example.ps1'
        if (Test-Path $modulePath) {
            . $modulePath
        }
    }
}
else {
    # Fallback for environments where Import-FragmentModule is not yet available
    $modulePath = Join-Path $PSScriptRoot 'modules' 'example.ps1'
    if (Test-Path $modulePath) {
        . $modulePath
    }
}
```

## Migration from Old Pattern

### Old Pattern (Manual Loading)

```powershell
# ❌ OLD: Manual path validation and loading
$moduleDir = Join-Path $PSScriptRoot 'dev-tools-modules'
if ($moduleDir -and -not [string]::IsNullOrWhiteSpace($moduleDir) -and (Test-Path -LiteralPath $moduleDir)) {
    $buildDir = Join-Path $moduleDir 'build'
    if ($buildDir -and -not [string]::IsNullOrWhiteSpace($buildDir) -and (Test-Path -LiteralPath $buildDir)) {
        $modulePath = Join-Path $buildDir 'build-tools.ps1'
        if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
            try {
                . $modulePath
            }
            catch {
                Write-Warning "Failed to load build-tools: $_"
            }
        }
    }
}
```

### New Pattern (Standardized Loading)

```powershell
# ✅ NEW: Standardized module loading
if (Get-Command Import-FragmentModule -ErrorAction SilentlyContinue) {
    Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('dev-tools-modules', 'build', 'build-tools.ps1') `
        -Context "Fragment: build-tools (build-tools.ps1)"
}
```

## Notes

- The module loading system uses `Test-ModulePath` from `ModulePathCache.ps1` for path caching
- Dependencies are checked by name (e.g., 'bootstrap', 'env') - they must be loaded before dependent modules
- Retry logic is useful for transient failures (file locks, network issues, etc.)
- Use `-Required` only for modules that are critical to fragment functionality
- Always provide meaningful `Context` strings for better error messages
- The system is backward compatible - fragments can check for `Import-FragmentModule` availability and fall back to manual loading
