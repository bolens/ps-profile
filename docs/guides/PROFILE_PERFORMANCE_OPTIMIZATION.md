# Profile Loading Performance Optimization Analysis

This document identifies areas where profile loading performance can be improved, based on analysis of the current implementation.

## Executive Summary

The profile loader already implements several performance optimizations (lazy loading, caching, dependency parsing cache). However, there are additional opportunities to reduce startup time, particularly in:

1. **Collection filtering operations** - Multiple `Where-Object` calls that could be optimized
2. **Module import overhead** - Redundant `Test-Path` and `Import-Module` calls
3. **Fragment file processing** - Inefficient collection operations during load order calculation
4. **Scoop detection** - Multiple filesystem checks that could be consolidated

## Current Performance Optimizations

The profile already implements these optimizations (documented in `ARCHITECTURE.md`):

✅ **Lazy Git Commit Hash Calculation** - Git hash calculated on-demand  
✅ **Fragment File List Caching** - Single `Get-ChildItem` call, cached result  
✅ **Fragment Dependency Parsing Cache** - Dependencies cached with file modification times  
✅ **Optimized Path Checks** - `Test-Path` results cached for modules  
✅ **Module Path Caching** - Paths computed once and reused

## Identified Optimization Opportunities

### 1. Collection Filtering in Profile Loader (High Impact)

**Location:** `Microsoft.PowerShell_profile.ps1` lines 359-360, 370, 377, 442-445, 454-457

**Issue:** Multiple `Where-Object` calls on fragment collections create new collections and iterate multiple times.

**Current Code:**

```powershell
$bootstrapFragment = $allFragments | Where-Object { $_.BaseName -eq '00-bootstrap' }
$otherFragments = $allFragments | Where-Object { $_.BaseName -ne '00-bootstrap' }
```

**Optimization:** Use a single pass to separate fragments:

```powershell
$bootstrapFragment = @()
$otherFragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
foreach ($fragment in $allFragments) {
    if ($fragment.BaseName -eq '00-bootstrap') {
        $bootstrapFragment += $fragment
    } else {
        $otherFragments.Add($fragment)
    }
}
```

**Impact:** Reduces from 2 collection iterations to 1, eliminates intermediate collections.

**Additional Optimization:** In batch optimization fallback (lines 442-445, 454-457), replace multiple `Where-Object` calls with a single pass:

```powershell
$tier0 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
$tier1 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
$tier2 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
$tier3 = [System.Collections.Generic.List[System.IO.FileInfo]]::new()

foreach ($fragment in $nonBootstrapFragments) {
    if ($fragment.BaseName -match '^0[1-9]-') {
        $tier0.Add($fragment)
    } elseif ($fragment.BaseName -match '^(1[0-9]|2[0-9])-') {
        $tier1.Add($fragment)
    } elseif ($fragment.BaseName -match '^([3-6][0-9])-') {
        $tier2.Add($fragment)
    } elseif ($fragment.BaseName -match '^([7-9][0-9])-') {
        $tier3.Add($fragment)
    }
}
```

**Impact:** Reduces from 4 collection iterations to 1.

### 2. Fragment Loading Module - Inefficient Lookup (Medium Impact)

**Location:** `scripts/lib/fragment/FragmentLoading.psm1` line 428

**Issue:** `Where-Object` used in a loop to check if fragment is already in sorted list.

**Current Code:**

```powershell
if ($sorted | Where-Object { $_.BaseName -eq $baseName }) {
    continue
}
```

**Optimization:** Use a HashSet for O(1) lookup:

```powershell
# At start of function, create a set for fast lookup
$sortedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

# When adding to sorted list:
if ($fragmentMap.ContainsKey($current)) {
    $sorted.Add($fragmentMap[$current])
    [void]$sortedNames.Add($current)
}

# In final loop:
if ($sortedNames.Contains($baseName)) {
    continue
}
```

**Impact:** Changes O(n) lookup to O(1) for each fragment check.

### 3. Load Order Override - Multiple Where-Object Calls (Medium Impact)

**Location:** `Microsoft.PowerShell_profile.ps1` lines 368-377

**Issue:** Multiple `Where-Object` calls and array concatenation in load order override logic.

**Current Code:**

```powershell
foreach ($fragmentName in $loadOrderOverride) {
    if ($fragmentName -eq '00-bootstrap') { continue }
    $fragment = $otherFragments | Where-Object { $_.BaseName -eq $fragmentName }
    if ($fragment) {
        $orderedFragments += $fragment
    }
}

$orderedNames = $orderedFragments | ForEach-Object { $_.BaseName }
$unorderedFragments = $otherFragments | Where-Object { $_.BaseName -notin $orderedNames } | Sort-Object Name
```

**Optimization:** Build a lookup dictionary and use HashSet for exclusion:

```powershell
# Build fragment lookup dictionary
$fragmentLookup = @{}
foreach ($fragment in $otherFragments) {
    $fragmentLookup[$fragment.BaseName] = $fragment
}

$orderedFragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
$orderedNames = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

foreach ($fragmentName in $loadOrderOverride) {
    if ($fragmentName -eq '00-bootstrap') { continue }
    if ($fragmentLookup.ContainsKey($fragmentName)) {
        $orderedFragments.Add($fragmentLookup[$fragmentName])
        [void]$orderedNames.Add($fragmentName)
    }
}

$unorderedFragments = [System.Collections.Generic.List[System.IO.FileInfo]]::new()
foreach ($fragment in $otherFragments) {
    if (-not $orderedNames.Contains($fragment.BaseName)) {
        $unorderedFragments.Add($fragment)
    }
}
$unorderedFragments = $unorderedFragments | Sort-Object Name
```

**Impact:** Reduces from O(n²) to O(n) complexity for load order override.

### 4. Module Import Caching (Low-Medium Impact)

**Location:** Various fragments, particularly `profile.d/02-files.ps1` and module loaders

**Issue:** Multiple fragments call `Test-Path` and `Import-Module` without cross-fragment caching.

**Current Pattern:**

```powershell
$modulePath = Join-Path $dir 'module.psm1'
if (Test-Path $modulePath) {
    Import-Module $modulePath -ErrorAction SilentlyContinue
}
```

**Optimization:** Create a global module import cache:

```powershell
# In 00-bootstrap.ps1 or GlobalState.ps1
if (-not $global:PSProfileModuleCache) {
    $global:PSProfileModuleCache = @{}
}

function Import-CachedModule {
    param([string]$ModulePath)

    $normalizedPath = [System.IO.Path]::GetFullPath($ModulePath)
    if ($global:PSProfileModuleCache.ContainsKey($normalizedPath)) {
        return $global:PSProfileModuleCache[$normalizedPath]
    }

    $exists = Test-Path $normalizedPath
    $global:PSProfileModuleCache[$normalizedPath] = $exists

    if ($exists) {
        Import-Module $normalizedPath -ErrorAction SilentlyContinue -DisableNameChecking
    }

    return $exists
}
```

**Impact:** Reduces redundant `Test-Path` calls across fragments that load similar modules.

### 5. Scoop Detection Optimization (Low Impact)

**Location:** `Microsoft.PowerShell_profile.ps1` lines 159-207

**Issue:** Multiple `Test-Path` calls in fallback detection, even though environment variables are checked first.

**Current Code:** Already optimized to check environment variables first, but could cache `Test-Path` results:

```powershell
# Cache Test-Path results for common paths
$scoopPathCache = @{}
function Test-ScoopPath {
    param([string]$Path)
    if (-not $scoopPathCache.ContainsKey($Path)) {
        $scoopPathCache[$Path] = Test-Path $Path -ErrorAction SilentlyContinue
    }
    return $scoopPathCache[$Path]
}
```

**Impact:** Minimal, as environment variable checks already avoid most filesystem operations.

### 6. Fragment Dependency Parsing - Batch Processing (Low Impact)

**Location:** `scripts/lib/fragment/FragmentLoading.psm1` `Get-FragmentDependencies`

**Issue:** Each fragment dependency is parsed individually, even though file content could be read once.

**Current Code:** Reads file content per fragment.

**Optimization:** If multiple fragments are being processed, could batch-read file contents, but current caching already handles this well.

**Impact:** Low - current caching is effective.

### 7. Environment Set Processing (Low Impact)

**Location:** `Microsoft.PowerShell_profile.ps1` lines 346-355

**Issue:** `ForEach-Object` and `Where-Object` used for environment set filtering.

**Current Code:**

```powershell
$allFragmentNames = $allFragments | ForEach-Object { $_.BaseName }
$disabledFragments = $allFragmentNames | Where-Object { $_ -notin $enabledFragments -and $_ -ne '00-bootstrap' }
```

**Optimization:** Use HashSet for faster lookups:

```powershell
$enabledSet = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
foreach ($name in $enabledFragments) {
    [void]$enabledSet.Add($name)
}

$disabledFragments = [System.Collections.Generic.List[string]]::new()
foreach ($fragment in $allFragments) {
    $baseName = $fragment.BaseName
    if ($baseName -ne '00-bootstrap' -and -not $enabledSet.Contains($baseName)) {
        $disabledFragments.Add($baseName)
    }
}
```

**Impact:** Low-Medium - only affects users with `PS_PROFILE_ENVIRONMENT` set.

## Performance Measurement

To measure the impact of these optimizations:

1. **Run baseline benchmark:**

   ```powershell
   pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -Iterations 10 -UpdateBaseline
   ```

2. **Apply optimizations** (one at a time or in batches)

3. **Re-run benchmark:**

   ```powershell
   pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -Iterations 10
   ```

4. **Compare results** - The benchmark script will automatically detect regressions/improvements.

## Recommended Implementation Order

1. **High Priority (High Impact, Low Risk):**

   - Collection filtering optimization (#1)
   - Fragment loading module lookup optimization (#2)

2. **Medium Priority (Medium Impact, Low Risk):**

   - Load order override optimization (#3)
   - Environment set processing (#7)

3. **Low Priority (Low Impact, Medium Risk):**
   - Module import caching (#4) - Requires careful testing to ensure modules load correctly
   - Scoop detection caching (#5) - Minimal impact, already well-optimized

## Additional Considerations

### Fragment-Level Optimizations

Individual fragments can also be optimized:

1. **Lazy Loading:** Ensure expensive operations are deferred behind `Enable-*` functions
2. **Provider-First Checks:** Use `Test-Path Function:\Name` instead of `Get-Command` when checking for existing functions
3. **Batch Module Loading:** Fragments that load many modules (e.g., `02-files.ps1`) could batch `Test-Path` checks

### Testing Requirements

All optimizations should:

- Maintain existing functionality
- Pass all existing tests
- Not break idempotency guarantees
- Be benchmarked before and after

### Documentation Updates

After implementing optimizations:

- Update `ARCHITECTURE.md` with new optimizations
- Update this document with actual performance improvements
- Consider adding performance regression tests to CI/CD

## Conclusion

The profile loader is already well-optimized with caching and lazy loading. The identified optimizations focus on:

1. **Reducing collection iterations** - Single-pass filtering instead of multiple `Where-Object` calls
2. **Improving lookup performance** - Using HashSets and dictionaries for O(1) lookups
3. **Caching module imports** - Reducing redundant filesystem operations

These optimizations should provide measurable improvements, especially for profiles with many fragments (80+ fragments). The most impactful changes are in the profile loader itself (#1, #2, #3), which affects every profile load.
