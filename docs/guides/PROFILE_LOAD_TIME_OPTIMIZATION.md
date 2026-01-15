# Profile Load Time Optimization Guide

This guide provides actionable recommendations to improve your PowerShell profile load times.

## Quick Start: Immediate Improvements

### 1. Disable Unused Fragments (Highest Impact)

The fastest way to improve load time is to disable fragments you don't use:

```powershell
# Create or edit .profile-fragments.json in your profile root
{
  "disabled": [
    "angular",
    "ansible",
    "azure",
    "beads",
    "bottom",
    "chocolatey",
    "cocoapods",
    "conan",
    "conda",
    "dart",
    "deno",
    "dotnet",
    "dust",
    "firebase",
    "gem",
    "gradle",
    "hatch",
    "helm",
    "homebrew",
    "julia",
    "laravel",
    "maven",
    "mix",
    "mojo",
    "nimble",
    "nuget",
    "nuxt",
    "ollama",
    "pdm",
    "php",
    "pip",
    "pipenv",
    "pixi",
    "poetry",
    "rye",
    "swift",
    "terraform",
    "uv",
    "vcpkg",
    "volta",
    "vue",
    "winget",
    "yarn"
  ]
}
```

**Expected Improvement:** 1-3 seconds (depends on how many fragments you disable)

### 2. Use Environment-Specific Loading

Load only what you need for specific environments:

```powershell
# Minimal profile (just essentials)
$env:PS_PROFILE_ENVIRONMENT = 'minimal'

# Configure in .profile-fragments.json
{
  "environments": {
    "minimal": [
      "bootstrap",
      "env",
      "system"
    ],
    "development": [
      "bootstrap",
      "env",
      "system",
      "files",
      "utilities",
      "git",
      "dev"
    ],
    "full": []  # Empty array = load all enabled fragments
  }
}
```

**Expected Improvement:** 2-5 seconds (depends on environment)

### 3. Enable Parallel Dependency Parsing (Already Enabled by Default)

Parallel dependency parsing is enabled by default and provides significant speedup. If disabled, enable it:

```powershell
# In .profile-fragments.json
{
  "performance": {
    "parallelDependencyParsing": true
  }
}
```

**Expected Improvement:** Already optimized (saves ~9.6 seconds on large profiles)

## Current Optimizations Already in Place ✅

Your profile already implements these optimizations:

1. **Module Path Caching** - `Test-Path` results cached to avoid redundant filesystem operations
2. **Lazy Module Loading** - Large fragments (like `files.ps1`) use deferred loading via module registry
3. **Fragment Dependency Parsing Cache** - Dependencies cached with file modification time tracking
4. **Fragment File List Caching** - Single `Get-ChildItem` call, cached result
5. **Lazy Git Commit Hash** - Calculated on-demand, not during startup
6. **Optimized Path Checks** - Scoop detection checks environment variables before filesystem
7. **Single-Pass Filtering** - Fragment discovery uses single-pass algorithms instead of multiple `Where-Object` calls
8. **HashSet Lookups** - O(1) lookups for fragment name checks

## Additional Optimization Opportunities

### 1. Disable Non-Essential Features

Review and disable features you rarely use:

```json
{
  "disabled": [
    "performance-insights", // Only needed for profiling
    "system-monitor", // Only needed for monitoring
    "enhanced-history", // Can use basic history
    "error-handling", // If you don't need enhanced error handling
    "diagnostics" // Only needed for diagnostics
  ]
}
```

### 2. Use Minimal Prompt Configuration

If you use Starship or oh-my-posh, simplify your prompt configuration:

```powershell
# Disable expensive prompt features
$env:STARSHIP_CONFIG = "$HOME\.config\starship\minimal.toml"
```

**Expected Improvement:** 50-200ms

### 3. Disable PSReadLine Features You Don't Use

PSReadLine can add overhead. Disable features you don't need:

```powershell
# In profile.d/psreadline.ps1 or your PSReadLine config
Set-PSReadLineOption -PredictionSource None  # Disable prediction if not used
Set-PSReadLineOption -HistorySearchCursorMovesToEnd $false
```

**Expected Improvement:** 100-300ms

### 4. Lazy Load Heavy Fragments

Some fragments can be loaded on-demand. Create lazy loaders for non-critical fragments:

```powershell
# Example: Lazy load performance insights
function Enable-PerformanceInsights {
    if ($global:PerformanceInsightsLoaded) { return }
    $global:PerformanceInsightsLoaded = $true
    . (Join-Path $PSScriptRoot 'performance-insights.ps1')
}

# Register as lazy function
Register-LazyFunction -Name 'Enable-PerformanceInsights' -Initializer { Enable-PerformanceInsights }
```

**Expected Improvement:** 100-500ms per deferred fragment

## Measuring Performance

### Benchmark Current Load Time

```powershell
# Run benchmark to measure current performance
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -Iterations 10

# Update baseline after optimizations
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -Iterations 10 -UpdateBaseline
```

### Enable Performance Profiling

```powershell
# Enable detailed timing information
$env:PS_PROFILE_DEBUG = '3'  # Performance profiling mode

# Reload profile and check timing data
. $PROFILE

# View fragment load times
$global:PSProfileFragmentTimes | Format-Table -AutoSize
```

### Identify Slow Fragments

```powershell
# After enabling debug mode, check which fragments take longest
$global:PSProfileFragmentTimes |
    Sort-Object -Property Duration -Descending |
    Select-Object -First 10 |
    Format-Table -AutoSize
```

## Configuration Recommendations by Use Case

### Minimal Profile (Fastest Startup)

```json
{
  "disabled": [
    "performance-insights",
    "system-monitor",
    "enhanced-history",
    "diagnostics",
    "error-handling"
  ],
  "environments": {
    "minimal": ["bootstrap", "env", "system"]
  },
  "performance": {
    "parallelDependencyParsing": true,
    "maxFragmentTime": 500
  }
}
```

**Expected Load Time:** 200-500ms

### Development Profile (Balanced)

```json
{
  "disabled": ["performance-insights", "system-monitor"],
  "environments": {
    "development": [
      "bootstrap",
      "env",
      "system",
      "files",
      "utilities",
      "git",
      "dev",
      "testing"
    ]
  },
  "performance": {
    "parallelDependencyParsing": true
  }
}
```

**Expected Load Time:** 500ms-1.5s

### Full Profile (All Features)

```json
{
  "disabled": [],
  "performance": {
    "parallelDependencyParsing": true
  }
}
```

**Expected Load Time:** 1-3s (depends on system)

## Advanced Optimizations

### 1. Fragment-Level Optimizations

For fragment authors, follow these patterns:

**Use Lazy Loading for Heavy Modules:**

```powershell
# ❌ BAD: Eager loading
Import-FragmentModule -ModulePath @('heavy-module.ps1')

# ✅ GOOD: Lazy loading via Ensure function
function Ensure-HeavyModule {
    if ($global:HeavyModuleInitialized) { return }
    $global:HeavyModuleInitialized = $true
    Import-FragmentModule -ModulePath @('heavy-module.ps1')
    # Initialize functions...
}
```

**Use Cached Path Checks:**

```powershell
# ❌ BAD: Direct Test-Path
if (Test-Path $modulePath) { ... }

# ✅ GOOD: Cached path check
if (Test-ModulePath -Path $modulePath) { ... }
```

**Use Provider-First Command Checks:**

```powershell
# ❌ BAD: Triggers module autoload
if (Get-Command 'MyCommand' -ErrorAction SilentlyContinue) { ... }

# ✅ GOOD: Fast provider check
if (Test-Path Function:\MyCommand) { ... }
```

### 2. Batch Module Loading

For fragments that load many modules, use batch loading:

```powershell
# ✅ GOOD: Batch load with Import-FragmentModules
Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules @(
    @{ ModulePath = @('module1.ps1'); Context = 'module1' },
    @{ ModulePath = @('module2.ps1'); Context = 'module2' },
    @{ ModulePath = @('module3.ps1'); Context = 'module3' }
)
```

### 3. Conditional Loading

Only load modules when conditions are met:

```powershell
# ✅ GOOD: Conditional loading
if (Test-CachedCommand 'docker') {
    Import-FragmentModule -ModulePath @('docker-helpers.ps1')
}
```

## Troubleshooting

### Profile Still Loading Slowly?

1. **Check fragment count:**

   ```powershell
   (Get-ChildItem profile.d/*.ps1).Count
   ```

2. **Identify slow fragments:**

   ```powershell
   $env:PS_PROFILE_DEBUG = '3'
   . $PROFILE
   $global:PSProfileFragmentTimes | Sort-Object Duration -Descending | Select-Object -First 5
   ```

3. **Check for eager module loading:**

   ```powershell
   # Search for fragments that load many modules eagerly
   Select-String -Path profile.d/*.ps1 -Pattern 'Import-FragmentModule' |
       Group-Object Path |
       Sort-Object Count -Descending
   ```

4. **Verify lazy loading is working:**
   ```powershell
   # Check if Ensure functions are being called
   $env:PS_PROFILE_DEBUG = '1'
   . $PROFILE
   # Look for "Loading modules for Ensure-*" messages
   ```

## Best Practices Summary

1. **Disable unused fragments** - Biggest impact
2. **Use environment-specific loading** - Load only what you need
3. **Lazy load heavy modules** - Defer until needed
4. **Use cached path checks** - `Test-ModulePath` instead of `Test-Path`
5. **Batch module loading** - Use `Import-FragmentModules` for multiple modules
6. **Conditional loading** - Only load when conditions are met
7. **Measure and monitor** - Use benchmark script to track improvements

## Expected Performance Targets

- **Minimal Profile:** < 500ms
- **Development Profile:** < 1.5s
- **Full Profile:** < 3s

Actual times depend on:

- System performance (SSD vs HDD, CPU speed)
- Number of fragments enabled
- Module file sizes
- PowerShell version

## Related Documentation

- [ARCHITECTURE.md](../../ARCHITECTURE.md) - System architecture and design decisions
- [PROFILE_LOADING_PERFORMANCE_ANALYSIS.md](./PROFILE_LOADING_PERFORMANCE_ANALYSIS.md) - Detailed performance analysis
- [PROFILE_PERFORMANCE_OPTIMIZATION.md](./PROFILE_PERFORMANCE_OPTIMIZATION.md) - Code-level optimizations
- [MODULE_LOADING_STANDARD.md](./MODULE_LOADING_STANDARD.md) - Module loading best practices
