# Profile Loading Performance Analysis

## Executive Summary

After investigating the profile loading system, several optimization opportunities have been identified. While many optimizations are already implemented (caching, lazy loading patterns, HashSet lookups), there are additional opportunities to improve startup time, particularly around eager module loading in large fragments.

## Current State

### Already Optimized ✅

1. **Fragment Loading Logic** - Single-pass filtering, HashSet lookups, dictionary-based fragment mapping
2. **Fragment Dependency Parsing** - Cached with file modification time tracking
3. **Module Path Caching** - Paths computed once and reused
4. **Lazy Git Commit Hash** - Calculated on-demand
5. **Scoop Detection** - Environment variables checked before filesystem operations

### Performance Bottlenecks Identified 🔍

#### 1. Eager Module Loading in `02-files.ps1` (HIGH IMPACT)

**Issue:** The `02-files.ps1` fragment loads **100+ module files eagerly** during profile initialization, even though the actual functionality is lazy-loaded via `Ensure-*` functions.

**Current Pattern:**

```powershell
# In 02-files.ps1 - loads 100+ modules eagerly
Import-FragmentModule -ModuleDir $coreDir -ModuleFile 'json.ps1'
Import-FragmentModule -ModuleDir $coreDir -ModuleFile 'yaml.ps1'
# ... 100+ more module loads
```

**Impact:** Each `Import-FragmentModule` call:

- Executes `Join-Path` operations
- Calls `Test-Path` to check file existence
- Dot-sources the entire module file (parsing, function definitions, etc.)
- Even if functions are lazy, the module parsing overhead accumulates

**Estimated Impact:** With 100+ modules, this could add 500ms-2s to startup time depending on:

- File system performance
- Module file sizes
- PowerShell parsing overhead

#### 2. Multiple `Test-Path` Calls in Module Loading (MEDIUM IMPACT)

**Issue:** Each fragment that loads modules performs individual `Test-Path` checks, even though many paths are checked multiple times across different fragments.

**Current Pattern:**

```powershell
# Each fragment checks paths independently
if (Test-Path $modulePath) {
    Import-Module $modulePath
}
```

**Impact:** Redundant filesystem operations, especially for commonly-used paths like:

- `scripts/lib/` modules
- Shared utility modules
- Runtime detection modules

#### 3. Fragment Module Discovery Overhead (LOW-MEDIUM IMPACT)

**Issue:** Fragments that load many sub-modules (like `02-files.ps1`, `05-utilities.ps1`) use explicit `Import-FragmentModule` calls for each module, requiring:

- Multiple `Join-Path` operations
- Multiple `Test-Path` checks
- Explicit module file enumeration

**Impact:** Code maintenance overhead and potential for missed optimizations.

## Recommended Optimizations

### Priority 1: Defer Module File Loading in `02-files.ps1` (HIGH IMPACT)

**Strategy:** Instead of loading all module files eagerly, load them only when their corresponding `Ensure-*` function is first called.

**Implementation Approach:**

1. **Create a module registry** that maps `Ensure-*` function names to module paths
2. **Modify `Ensure-*` functions** to load their modules on first call
3. **Remove eager `Import-FragmentModule` calls** from `02-files.ps1`

**Example:**

```powershell
# In 02-files.ps1 - replace eager loading with registry
$script:FileConversionModuleRegistry = @{
    'Ensure-FileConversion-Data' = @(
        @{ Dir = 'conversion-modules/data/core'; File = 'json.ps1' }
        @{ Dir = 'conversion-modules/data/core'; File = 'yaml.ps1' }
        # ... registry entries
    )
}

# Ensure-* functions load modules on first call
function Ensure-FileConversion-Data {
    if ($global:FileConversionDataInitialized) { return }

    # Load modules from registry
    foreach ($module in $script:FileConversionModuleRegistry['Ensure-FileConversion-Data']) {
        $modulePath = Join-Path $PSScriptRoot $module.Dir $module.File
        if (Test-Path $modulePath) {
            . $modulePath
        }
    }

    # Then initialize functions
    Initialize-FileConversion-CoreBasicJson
    # ... rest of initialization
}
```

**Expected Improvement:** 500ms-2s reduction in startup time (depending on system)

**Risk:** Low - functionality remains the same, just deferred

### Priority 2: Module Path Existence Cache (MEDIUM IMPACT)

**Strategy:** Create a global cache for `Test-Path` results on module paths to avoid redundant filesystem checks.

**Implementation:**

```powershell
# In 00-bootstrap.ps1 or GlobalState.ps1
if (-not $global:PSProfileModulePathCache) {
    $global:PSProfileModulePathCache = @{}
}

function Test-ModulePath {
    param([string]$Path)

    $normalizedPath = [System.IO.Path]::GetFullPath($Path)
    if (-not $global:PSProfileModulePathCache.ContainsKey($normalizedPath)) {
        $global:PSProfileModulePathCache[$normalizedPath] = Test-Path $normalizedPath -ErrorAction SilentlyContinue
    }
    return $global:PSProfileModulePathCache[$normalizedPath]
}
```

**Expected Improvement:** 50-200ms reduction (depends on number of redundant checks)

**Risk:** Very Low - simple caching layer

### Priority 3: Batch Module Path Resolution (LOW-MEDIUM IMPACT)

**Strategy:** For fragments that load many modules, batch the path resolution and existence checks.

**Implementation:**

```powershell
function Import-FragmentModules {
    param(
        [string]$BaseDir,
        [string[]]$ModuleFiles
    )

    # Batch resolve all paths
    $modulePaths = $ModuleFiles | ForEach-Object {
        $path = Join-Path $BaseDir $_
        @{
            Path = $path
            Exists = Test-ModulePath $path
        }
    }

    # Load only existing modules
    foreach ($module in $modulePaths) {
        if ($module.Exists) {
            . $module.Path
        }
    }
}
```

**Expected Improvement:** 50-150ms reduction (reduces overhead from repeated path operations)

**Risk:** Low - improves efficiency without changing behavior

### Priority 4: Lazy Load Non-Critical Fragments (MEDIUM IMPACT)

**Strategy:** Identify fragments that aren't needed immediately and defer their loading.

**Candidates for Lazy Loading:**

- `73-performance-insights.ps1` - Can be loaded on first use
- `74-enhanced-history.ps1` - Can be loaded when history is accessed
- `75-system-monitor.ps1` - Can be loaded when monitoring is needed
- Some conversion modules - Already lazy, but could be more aggressive

**Implementation Pattern:**

```powershell
# Instead of loading fragment directly, register lazy loader
Register-LazyFragment -Name '73-performance-insights' -Loader {
    . (Join-Path $PSScriptRoot '73-performance-insights.ps1')
}
```

**Expected Improvement:** 100-500ms reduction (depends on which fragments are deferred)

**Risk:** Medium - requires careful analysis of fragment dependencies

## Measurement Strategy

### Before Optimization

```powershell
# Run benchmark to establish baseline
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -Iterations 10 -UpdateBaseline
```

### After Each Optimization

```powershell
# Measure improvement
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -Iterations 10
```

### Enable Debug Timing

```powershell
$env:PS_PROFILE_DEBUG = '3'  # Enable performance profiling
# Reload profile and check $global:PSProfileFragmentTimes
```

## Implementation Plan

### Phase 1: Quick Wins (Low Risk, Medium Impact)

1. ✅ Implement module path existence cache
2. ✅ Batch module path resolution in high-load fragments
3. ✅ Measure improvements

### Phase 2: Deferred Loading (Medium Risk, High Impact)

1. ✅ Refactor `02-files.ps1` to use module registry
2. ✅ Update `Ensure-*` functions to load modules on demand
3. ✅ Test thoroughly to ensure lazy loading works correctly
4. ✅ Measure improvements

### Phase 3: Advanced Optimizations (Higher Risk, Variable Impact)

1. ✅ Identify additional fragments for lazy loading
2. ✅ Implement lazy fragment loading system
3. ✅ Update documentation
4. ✅ Measure improvements

## Additional Considerations

### Fragment Dependencies

When implementing lazy loading, ensure fragment dependencies are respected:

- Fragments that other fragments depend on should load eagerly
- Use `#Requires -Fragment` declarations to track dependencies
- Test dependency resolution after changes

### Error Handling

Lazy loading should maintain the same error handling:

- Silent failures for missing modules (non-critical)
- Clear errors for critical module failures
- Debug mode should show what's being loaded

### Testing

All optimizations should:

- Pass existing tests
- Maintain idempotency guarantees
- Not break fragment dependency resolution
- Be benchmarked before and after

## Expected Overall Improvement

With all optimizations implemented:

- **Conservative estimate:** 500ms-1s improvement
- **Optimistic estimate:** 1-3s improvement
- **Best case (slow systems):** 2-5s improvement

Actual improvement depends on:

- System performance (SSD vs HDD, CPU speed)
- Number of fragments loaded
- Module file sizes
- PowerShell version

## Monitoring

After implementing optimizations:

1. Monitor startup times in production
2. Track fragment load times with `$env:PS_PROFILE_DEBUG=3`
3. Update baseline benchmarks
4. Document actual improvements achieved

## Related Documents

- `PROFILE_PERFORMANCE_OPTIMIZATION.md` - Detailed code-level optimizations
- `PROFILE_PERFORMANCE_SUMMARY.md` - Quick reference
- `ARCHITECTURE.md` - System architecture and design decisions
