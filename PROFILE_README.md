# PowerShell Profile Technical Documentation

This document provides detailed technical information about the profile architecture, internals, and advanced usage. For quick start and general information, see [README.md](README.md).

## Architecture Overview

### Profile Loader

`Microsoft.PowerShell_profile.ps1` is the main entrypoint that:

- Loads fragments from `profile.d/` with dependency-aware ordering
- Includes robust error handling that reports which fragment failed to load
- Supports batch-optimized loading for better performance
- Keeps itself minimal—all functionality lives in fragments

### Fragment Loading Order

Fragments use **dependency-aware loading** with explicit dependency declarations. Fragments are organized by **tiers** for batch optimization:

**Tier Organization:**

- **Core (Tier 0)**: Critical bootstrap and initialization (e.g., `bootstrap.ps1`)
- **Essential (Tier 1)**: Core functionality needed by most workflows (e.g., `env.ps1`, `files.ps1`, `utilities.ps1`)
- **Standard (Tier 2)**: Common development tools (e.g., `git.ps1`, `containers.ps1`, `aws.ps1`)
- **Optional (Tier 3)**: Advanced features (e.g., `performance-insights.ps1`, `system-monitor.ps1`)

**Dependency Declarations:**
Fragments declare dependencies in their header:

```powershell
# Dependencies: bootstrap, env
# Tier: standard
```

Or using `#Requires` syntax:

```powershell
#Requires -Fragment 'bootstrap'
#Requires -Fragment 'env'
```

The loader automatically resolves dependencies using topological sorting and loads fragments in the correct order. Fragments without explicit dependencies are loaded alphabetically within their tier.

## Fragment Configuration

### Basic Configuration

Fragments can be enabled/disabled via `.profile-fragments.json`:

```json
{
  "disabled": ["git"]
}
```

Or using commands:

```powershell
Disable-ProfileFragment -FragmentName 'git'
Enable-ProfileFragment -FragmentName 'git'
Get-ProfileFragment  # List all fragments
```

### Enhanced Configuration

The `.profile-fragments.json` file supports advanced options:

```json
{
  "disabled": ["git"],
  "loadOrder": ["bootstrap", "env", "utilities"],
  "environments": {
    "minimal": ["bootstrap", "env"],
    "development": ["bootstrap", "env", "git", "dev"],
    "ci": [
      "bootstrap",
      "env",
      "files",
      "utilities",
      "system",
      "git",
      "error-handling"
    ],
    "cloud": [
      "bootstrap",
      "env",
      "aws",
      "azure",
      "gcloud",
      "terraform",
      "kube",
      "containers"
    ]
  },
  "featureFlags": {
    "enableAdvancedFeatures": true
  },
  "performance": {
    "batchLoad": true,
    "parallelDependencyParsing": true,
    "maxFragmentTime": 500
  }
}
```

**Environment-Specific Loading:**

```powershell
$env:PS_PROFILE_ENVIRONMENT = 'minimal'
. $PROFILE
```

**Automatic Environment Management:**

Instead of manually maintaining environment lists in `.profile-fragments.json`, you can use the automatic sync utility:

```powershell
# Sync .profile-fragments.json automatically based on fragment metadata
pwsh -NoProfile -File scripts/utils/fragment/sync-profile-fragments.ps1

# Preview changes without modifying the file
pwsh -NoProfile -File scripts/utils/fragment/sync-profile-fragments.ps1 -DryRun
```

The sync utility automatically:

- Discovers all fragments in `profile.d/`
- Parses metadata (Tier, Dependencies, Environment tags)
- Assigns fragments to environments based on:
  - **Explicit tags**: `# Environment: minimal, development, cloud` in fragment headers
  - **Tier-based rules**: minimal = core+essential
  - **Keyword matching**: container fragments → containers environment, cloud fragments → cloud environment, etc.
- **Special handling**: The `full` environment automatically loads all fragments (no list maintained in config)
- Preserves manual overrides (use `-PreserveManual` flag)

**Fragment Metadata Tags:**

Fragments can declare environment assignments in their headers:

```powershell
# Tier: standard
# Dependencies: bootstrap, env
# Environment: cloud, development
```

**Load All Fragments (Override Restrictions):**

```powershell
# Load all fragments, ignoring disabled fragments and environment restrictions
$env:PS_PROFILE_LOAD_ALL = '1'
. $PROFILE
```

This is useful for:

- Testing all fragments
- Full profile loading when you want everything enabled
- Overriding environment-specific restrictions temporarily

**Batch-Optimized Loading:**

```powershell
$env:PS_PROFILE_BATCH_LOAD = '1'
. $PROFILE
```

Or configure in `.profile-fragments.json`:

```json
{
  "performance": {
    "batchLoad": true
  }
}
```

## Bootstrap Helpers

`bootstrap.ps1` provides three collision-safe registration helpers:

### Set-AgentModeFunction

Creates functions without overwriting existing commands:

```powershell
Set-AgentModeFunction -Name 'MyFunc' -Body { Write-Output "Hello" }

# Return the ScriptBlock for programmatic use
$sb = Set-AgentModeFunction -Name 'myfn' -Body { 'hi' } -ReturnScriptBlock
```

### Set-AgentModeAlias

Creates aliases or function wrappers without overwriting:

```powershell
Set-AgentModeAlias -Name 'gs' -Target 'git status'

# Return the textual alias wrapper definition
$def = Set-AgentModeAlias -Name 'gs' -Target 'git status' -ReturnDefinition
```

### Test-CachedCommand

Fast command existence check with caching:

```powershell
if (Test-CachedCommand 'docker') { # configure docker helpers }
```

## Performance Optimizations

The profile implements multiple layers of performance optimizations to ensure fast startup times:

### Profile Loader Optimizations

**1. Lazy Git Commit Hash Calculation**

- Git commit hash is calculated on-demand rather than during startup
- Only runs when accessed (e.g., in debug mode) to avoid blocking startup with a git subprocess
- Uses a lazy getter function that caches the result after first access

**2. Fragment File List Caching**

- Fragment file list is retrieved once using `Get-ChildItem` and cached
- Eliminates duplicate file system operations during loading
- Reduces I/O overhead, especially on slower file systems

**3. Fragment Dependency Parsing Cache**

- `FragmentLoading.psm1` caches parsed dependencies with file modification times
- Dependencies are only re-parsed when fragment files change
- Cache automatically invalidates when files are modified
- Significantly reduces file reading and parsing operations for large profiles

**4. Parallel Dependency Parsing**

- For profiles with 5+ fragments, dependencies are parsed in parallel using PowerShell runspaces
- Speeds up I/O-bound dependency parsing operations significantly (reduced from ~10s to <400ms, 25x faster)
- Enabled by default, controlled via `PS_PROFILE_PARALLEL_DEPENDENCIES` environment variable
- Uses runspaces instead of jobs for much better performance (no process spawning overhead)
- Falls back to sequential parsing if parallel execution fails

**5. Optimized Path Checks**

- `Test-Path` results are cached for module existence checks
- Module paths are computed once and reused throughout loading
- Scoop detection optimized to check environment variables before filesystem operations
- Reduces redundant filesystem operations

**6. Module Path Caching**

- Fragment management module paths computed once and stored
- Eliminates repeated `Join-Path` operations
- Module existence checks cached to avoid repeated `Test-Path` calls

**7. Experimental Parallel Fragment Loading**

- **EXPERIMENTAL**: Hybrid approach that attempts to load independent fragments (same dependency level) in parallel using PowerShell runspaces
- Automatically falls back to sequential loading if parallel execution fails or is not fully supported
- Enable via `PS_PROFILE_PARALLEL_LOADING=1` environment variable
- **Warning**: Experimental feature - may have issues with fragments that modify session state extensively
- Fragment execution is sequential by default for reliability

### Fragment-Level Optimizations

**Lazy Loading Pattern**

Heavy initialization is deferred behind `Enable-*` functions:

```powershell
# In fragment: register enabler function only
Set-AgentModeFunction -Name 'Enable-MyTool' -Body {
    # Expensive work happens here when user calls Enable-MyTool
    Import-Module MyExpensiveModule
    Set-AgentModeAlias -Name 'mt' -Target 'mytool'
}
```

**Provider-First Checks**

Use `Test-Path` on providers to avoid module autoload and disk I/O:

```powershell
# Fast: checks provider without loading modules
if (Test-Path Function:\MyFunction) { return }

# Slow: may trigger module autoload
if (Get-Command MyFunction -ErrorAction SilentlyContinue) { return }
```

### Benchmarking

Measure startup performance:

```powershell
pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -Iterations 30
# Or use task: task benchmark
```

Update performance baseline after optimizations:

```powershell
pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -UpdateBaseline
# Or use task: task update-baseline
```

Outputs `scripts/data/startup-benchmark.csv` with per-fragment timings. See [PROFILE_DEBUG.md](PROFILE_DEBUG.md) for micro-instrumentation.

## Container Engine Support

### Auto-Detection

`containers.ps1` provides:

- Auto-detection of Docker or Podman with compose support
- Unified aliases (`dcu`, `dcd`, `dcl`, `dprune`, etc.) that work with either engine
- Session-level preference setting

### Setting Preference

```powershell
Set-ContainerEnginePreference docker  # or 'podman'
Test-ContainerEngine  # Inspect current configuration
```

Returns object with `Engine`, `Compose` (subcommand), and `Preferred` values.

## Prompt Frameworks

Two prompt systems are supported with lazy initialization:

- **oh-my-posh** (`oh-my-posh.ps1`): Use `Initialize-OhMyPosh` to activate
- **Starship** (`starship.ps1`): Use `Initialize-Starship` to activate

If neither is installed, PowerShell uses its default prompt. The profile does not override existing prompt configurations.

## Fragment Idempotency

All fragments MUST be idempotent (safe to source multiple times). Patterns:

```powershell
# Use bootstrap helpers (recommended)
Set-AgentModeFunction -Name 'MyFunc' -Body { ... }

# Or guard with provider checks
if (-not (Test-Path Function:\MyFunc)) {
    function MyFunc { ... }
}

# Guard external tool calls
if (Test-CachedCommand 'docker') {
    # configure docker helpers
}
```

## PSScriptAnalyzer Configuration

`PSScriptAnalyzerSettings.psd1` disables noisy rules for interactive profile code:

- Allows cmdlet aliases
- Allows `Write-Host` for user feedback
- Per-file suppressions for known acceptable patterns

Edit this file to customize linting behavior.

## Debug & Instrumentation

### PS_PROFILE_DEBUG

Enable verbose output from bootstrap helpers:

```powershell
$env:PS_PROFILE_DEBUG = '1'
$VerbosePreference = 'Continue'
. $PROFILE
```

In CI, helpers write to stdout for GitHub Actions logs.

### PS_PROFILE_DEBUG_TIMINGS

Enable micro-instrumentation CSV output:

```powershell
$env:PS_PROFILE_DEBUG_TIMINGS = '1'
. $PROFILE
```

Check generated CSV files in `scripts/data/` (e.g., `alias-instrument.csv`).

See [PROFILE_DEBUG.md](PROFILE_DEBUG.md) for complete debugging guide.

## Environment Variable Configuration

The profile supports project-specific environment variable configuration through `.env` files. This allows you to customize package manager preferences and other settings without modifying system environment variables.

### .env File Support

Create a `.env` file (or `.env.local` for local-only settings) in the repository root to configure preferences:

```bash
# .env
PS_PYTHON_PACKAGE_MANAGER=uv
PS_NODE_PACKAGE_MANAGER=pnpm
PS_DATA_FRAME_LIB=polars
PS_PARQUET_LIB=pyarrow
PS_SCIENTIFIC_LIB=xarray
PS_PROFILE_ENVIRONMENT=minimal
PS_PROFILE_BATCH_LOAD=1
```

**File Loading Order:**

1. `.env` - Base configuration (committed to repository)
2. `.env.local` - Local overrides (gitignored, overrides `.env`)

**Supported Environment Variables:**

- `PS_PYTHON_PACKAGE_MANAGER` - Preferred Python package manager (`auto`, `uv`, `pip`, `conda`, `poetry`, `pipenv`)
- `PS_NODE_PACKAGE_MANAGER` - Preferred Node.js package manager (`auto`, `pnpm`, `npm`, `yarn`, `bun`)
- `PS_DATA_FRAME_LIB` - Preferred data frame library (`auto`, `pandas`, `polars`)
- `PS_PARQUET_LIB` - Preferred Parquet library (`auto`, `pyarrow`, `fastparquet`)
- `PS_SCIENTIFIC_LIB` - Preferred scientific library (`auto`, `netcdf4`, `h5py`, `xarray`)
- `PS_PROFILE_ENVIRONMENT` - Environment-specific fragment loading (e.g., `minimal`, `development`, `ci`, `cloud`, `server`, `containers`, `web`, `full`). Requires configuration in `.profile-fragments.json`
- `PS_PROFILE_LOAD_ALL` - Load all fragments (`0` or `1`, default: `0`). When enabled, loads all fragments regardless of disabled fragments list or environment restrictions. Overrides `PS_PROFILE_ENVIRONMENT` and `.profile-fragments.json` disabled list
- `PS_PROFILE_BATCH_LOAD` - Enable batch loading optimization (`0` or `1`)
- `PS_PROFILE_PARALLEL_DEPENDENCIES` - Enable parallel dependency parsing (`0` or `1`, default: `1`). Speeds up dependency parsing for profiles with 5+ fragments
- `PS_PROFILE_PARALLEL_LOADING` - **EXPERIMENTAL**: Enable parallel fragment loading (`0` or `1`, default: `0`). Attempts to load independent fragments in parallel, falls back to sequential on failure
- `PS_PROFILE_DEBUG` - Enable debug output (`0` or `1`)
- `PS_PROFILE_DEBUG_TIMINGS` - Enable performance timing (`0` or `1`)
- `PS_PROFILE_ENABLE_LOCAL_OVERRIDES` - Enable local-overrides.ps1 loading (`0` or `1`, default: `0`) - **WARNING**: Disabled by default due to performance issues (100+ second delays on some filesystems when file doesn't exist)

**Features:**

- Comments supported (lines starting with `#`)
- Quoted values (single or double quotes)
- Variable expansion (`$VAR` or `${VAR}`)
- Safe defaults (doesn't overwrite existing environment variables unless using `.env.local` with `Overwrite`)

See `.env.example` for a complete example with all available options.

## Fragment Development

### Creating New Fragments

1. Create file in `profile.d/` with descriptive name (e.g., `dev.ps1`)
2. Keep it focused on a single concern
3. Ensure idempotency using bootstrap helpers or guards
4. Guard external tool calls with `Test-CachedCommand` or `Get-Command`
5. Avoid side effects during dot-sourcing (defer to `Enable-*` functions)

### Modular Fragment Structure

Many fragments use a modular subdirectory structure where the main fragment loads related modules:

**Module Organization:**

- Main fragments (e.g., `files.ps1`, `utilities.ps1`) act as orchestrators
- Related functionality is organized in subdirectories:
  - **`cli-modules/`** - Modern CLI tool integrations
  - **`container-modules/`** - Container helper modules (Docker/Podman)
  - **`conversion-modules/`** - Data/document/media format conversions
    - `data/` with subdirectories: `binary/`, `columnar/`, `core/`, `scientific/`, `structured/`
    - `document/` - Document format conversions
    - `helpers/` - Conversion helper utilities
    - `media/` - Media format conversions including color conversions
  - **`dev-tools-modules/`** - Development tool integrations
    - `build/`, `crypto/`, `data/`, `encoding/`, `format/` (with `qrcode/` subdirectory)
  - **`diagnostics-modules/`** - Diagnostic and monitoring modules
  - **`files-modules/`** - File operation modules
  - **`git-modules/`** - Git integration modules
  - **`utilities-modules/`** - Utility function modules
- Modules are dot-sourced by the parent fragment during load

**Example Module Loading:**

```powershell
# In utilities.ps1
$utilitiesModulesDir = Join-Path $PSScriptRoot 'utilities-modules'
if (Test-Path $utilitiesModulesDir) {
    $systemDir = Join-Path $utilitiesModulesDir 'system'
    . (Join-Path $systemDir 'utilities-profile.ps1')
    . (Join-Path $systemDir 'utilities-security.ps1')
    # ... more modules
}
```

**When to Use Modules:**

- Large fragments that can be split into logical groups
- Functionality that's shared across multiple fragments
- Related utilities that belong together (e.g., all conversion functions)
- Code that benefits from better organization

**Module Guidelines:**

- Modules should be idempotent (safe to dot-source multiple times)
- Use `Set-AgentModeFunction` for function registration
- Include error handling for module loading failures
- Document all exported functions with comment-based help

### Best Practices

- **No expensive operations**: Defer module imports, file I/O, network calls
- **Provider-first checks**: Use `Test-Path Function:\Name` over `Get-Command`
- **Cached commands**: Use `Test-CachedCommand` to avoid repeated lookups
- **Clear documentation**: Add comment-based help to functions

## API Documentation

Function and alias documentation is auto-generated from comment-based help:

```powershell
pwsh -NoProfile -File scripts/utils/generate-docs.ps1
```

Outputs to `docs/*.md`. See [docs/README.md](docs/README.md) for the generated index.

## Related Documentation

- [README.md](README.md) — Quick start and overview
- [CONTRIBUTING.md](CONTRIBUTING.md) — Development guidelines
- [PROFILE_DEBUG.md](PROFILE_DEBUG.md) — Debugging and instrumentation
- [powershell.config.README.md](powershell.config.README.md) — Configuration details
- [docs/guides/DEVELOPMENT.md](docs/guides/DEVELOPMENT.md) — Developer guide and advanced testing
- [WARP.md](WARP.md) — WARP development guide
- [AGENTS.md](AGENTS.md) — AI coding assistant guidance
