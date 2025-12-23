# PowerShell Profile Architecture

This document provides detailed technical information about the profile architecture, internals, and design decisions.

## Overview

The PowerShell profile is designed as a modular, performance-optimized system that loads functionality from named fragments in `profile.d/` using dependency-aware loading. This architecture enables:

- **Fast startup**: Lazy loading and deferred initialization
- **Maintainability**: Small, focused fragments
- **Extensibility**: Easy to add new functionality
- **Cross-platform**: Works on Windows, Linux, and macOS

### Fragment Management Modules

The profile uses specialized modules in `scripts/lib/` for fragment management. The `scripts/lib/` directory is organized into category-based subdirectories:

- **`fragment/`** - Fragment-related modules:
  - **`FragmentConfig.psm1`** - Configuration parsing from `.profile-fragments.json`
  - **`FragmentLoading.psm1`** - Dependency resolution and load order calculation
  - **`FragmentIdempotency.psm1`** - Idempotency state management
  - **`FragmentErrorHandling.psm1`** - Standardized error handling
- **`runtime/`** - Runtime environment modules:
  - **`ScoopDetection.psm1`** - Scoop installation detection and PATH management

**Note**: The `ModuleImport.psm1` module (located in `scripts/lib/` root) automatically resolves subdirectories when using `Import-LibModule`, so you don't need to specify subdirectory paths when importing modules.

These modules are imported in `Microsoft.PowerShell_profile.ps1` before fragments are loaded, making them available to all fragments.

## Profile Loader

`Microsoft.PowerShell_profile.ps1` is the main entrypoint that:

1. Checks for interactive session (skips non-interactive hosts)
2. Tracks profile version (git commit hash loaded lazily to avoid blocking startup)
3. Detects and configures Scoop (if installed) with optimized path checks
4. Loads fragments from `profile.d/` in dependency-aware order with caching optimizations
5. Initializes prompt framework (Starship or fallback)
6. Includes robust error handling that reports which fragment failed

### Performance Optimizations

The profile loader implements several performance optimizations to minimize startup time:

**1. Lazy Git Commit Hash Calculation**

- Git commit hash is calculated on-demand rather than during startup
- Only runs when accessed (e.g., in debug mode) to avoid blocking startup
- Uses a lazy getter function that caches the result after first access

**2. Fragment File List Caching**

- Fragment file list is retrieved once and cached
- Eliminates duplicate `Get-ChildItem` calls during loading
- Reduces file system I/O operations

**3. Fragment Dependency Parsing Cache**

- `FragmentLoading.psm1` caches parsed dependencies with file modification times
- Dependencies are only re-parsed when fragment files change
- Cache automatically invalidates when files are modified
- Significantly reduces file reading and parsing operations

**4. Optimized Path Checks**

- `Test-Path` results are cached for module existence checks
- Module paths are computed once and reused
- Scoop detection optimized to check environment variables before filesystem operations
- Reduces redundant filesystem operations

**5. Module Path Caching**

- Fragment management module paths computed once and stored
- Eliminates repeated `Join-Path` operations
- Module existence checks cached to avoid repeated `Test-Path` calls

### Fragment Loading Process

Fragments are loaded in sorted order (00-99 prefix) with optional batch optimization:

**Default Mode (Sequential):**

```powershell
# All fragments loaded sequentially in lexical order
Get-ChildItem -Path $profileD -File -Filter '*.ps1' |
    Sort-Object Name |
    ForEach-Object {
        try {
            $null = . $_.FullName
        }
        catch {
            # Report error but continue loading other fragments
        }
    }
```

**Batch-Optimized Mode (Optional):**
Enable with `$env:PS_PROFILE_BATCH_LOAD=1`:

- **Tier 0 (Core)**: Critical bootstrap fragments (e.g., `bootstrap.ps1`) - loaded sequentially first
- **Tier 1 (Essential)**: Core functionality fragments (e.g., `env.ps1`, `files.ps1`, `utilities.ps1`) - loaded sequentially after tier 0
- **Tier 2 (Standard)**: Common development tools (e.g., `git.ps1`, `containers.ps1`, `aws.ps1`) - loaded sequentially after tier 1
- **Tier 3 (Optional)**: Advanced features (e.g., `performance-insights.ps1`, `system-monitor.ps1`) - loaded sequentially after tier 2

**Key characteristics:**

- Fragments are loaded using dependency-aware topological sorting
- Fragments declare dependencies explicitly in their headers: `# Dependencies: bootstrap, env`
- Fragments can declare tiers: `# Tier: standard`
- Each fragment is wrapped in try-catch to prevent one failure from stopping all
- Fragments can be disabled via `.profile-fragments.json`
- Loading is idempotent (safe to reload)
- Batch optimization groups fragments by dependency tiers for more efficient loading
- **Parallel dependency parsing:** Fragments with 5+ files automatically parse dependencies in parallel using PowerShell runspaces, significantly reducing I/O overhead (from ~10s to <400ms). Control via `PS_PROFILE_PARALLEL_DEPENDENCIES` (default: enabled). Uses runspaces instead of jobs for much better performance (no process spawning overhead).
- **EXPERIMENTAL: Parallel fragment loading:** Hybrid approach that attempts to load independent fragments (same dependency level) in parallel using PowerShell runspaces, then falls back to sequential loading if parallel execution fails. Enable via `PS_PROFILE_PARALLEL_LOADING=1`. WARNING: Experimental feature - may have issues with fragments that modify session state extensively
- **Note:** Fragment execution is sequential by default for reliability. Parallel dependency parsing is enabled by default and provides significant speedup. Parallel fragment loading is experimental and opt-in. All parallel processing now uses runspaces (not jobs) for optimal performance.

## Fragment Structure

### Naming Convention

Fragments use descriptive names and explicit dependency declarations:

- **Core Tier**: Critical bootstrap and initialization (e.g., `bootstrap.ps1`)
- **Essential Tier**: Core functionality needed by most workflows (e.g., `env.ps1`, `files.ps1`, `utilities.ps1`)
- **Standard Tier**: Common development tools (e.g., `git.ps1`, `containers.ps1`, `aws.ps1`, `dev.ps1`)
- **Optional Tier**: Advanced features (e.g., `performance-insights.ps1`, `system-monitor.ps1`)

Fragments declare dependencies in their headers:

```powershell
# Dependencies: bootstrap, env
# Tier: standard
```

Load order is determined by dependency resolution (topological sorting), not numeric prefixes. This allows for unlimited scalability and clearer dependency relationships.

### Modular Subdirectory Organization

Many fragments have been refactored to use a modular subdirectory structure. Main fragments (e.g., `files.ps1`, `utilities.ps1`) load related modules from subdirectories:

**Module Subdirectories:**

- **`cli-modules/`** - Modern CLI tool integrations (gum, navi, eza, etc.)
- **`container-modules/`** - Container helper modules (Docker/Podman compose, utilities)
- **`conversion-modules/`** - Data, document, and media format conversion utilities
  - `data/` - Data format conversions
    - `binary/` - Binary format conversions (direct, schema formats: Avro, FlatBuffers, Protobuf, Thrift)
    - `columnar/` - Columnar format conversions (Arrow, Parquet, CSV)
    - `core/` - Core data conversions (base64, CSV, JSON, XML, YAML, encoding utilities)
    - Encoding sub-modules: `core-encoding-*.ps1` (ASCII, Binary, Base32, Hex, ModHex, Numeric, Roman, URL)
    - `scientific/` - Scientific format conversions (HDF5, NetCDF)
    - `structured/` - Structured data formats (SuperJSON, TOML, TOON)
  - `document/` - Document format conversions (DOCX, EPUB, HTML, LaTeX, Markdown, RST)
  - `helpers/` - Conversion helper utilities (TOON, XML)
  - `media/` - Media format conversions
    - Audio, image, PDF, video conversions
    - Color format conversions (CMYK, HEX, HSL, HWB, LAB, LCH, named colors, NCOL, OKLAB, OKLCH, parsing)
- **`dev-tools-modules/`** - Development tool integrations
  - `build/` - Build tools and testing frameworks
  - `crypto/` - Cryptographic utilities (hash, JWT)
  - `data/` - Data manipulation tools (lorem, number base conversion, timestamps, units, UUID)
  - `encoding/` - Encoding utilities (base encoding, character encoding)
  - `format/` - Formatting tools
    - `diff/` - Diff utilities
    - `qrcode/` - QR code generation (communication, formats, specialized)
    - `regex/` - Regular expression utilities
- **`diagnostics-modules/`** - Diagnostic and monitoring modules
  - `core/` - Core diagnostics (error handling, profile diagnostics)
  - `monitoring/` - System monitoring (performance, system monitor)
- **`files-modules/`** - File operation modules
  - `inspection/` - File inspection utilities (hash, head/tail, hexdump, size)
  - `navigation/` - File navigation helpers (listing, navigation)
- **`git-modules/`** - Git integration modules
  - `core/` - Core Git operations (basic, advanced, helpers)
  - `integrations/` - Git service integrations (GitHub)
- **`utilities-modules/`** - Utility function modules
  - `data/` - Data utilities (datetime, encoding)
  - `filesystem/` - Filesystem utilities
  - `history/` - Command history utilities (basic, enhanced)
  - `network/` - Network utilities (basic, advanced)
  - `system/` - System utilities (env, profile, security)

**Module Loading Pattern:**

Main fragments dot-source modules from their respective subdirectories:

```powershell
# Example from 02-files.ps1
$conversionModulesDir = Join-Path $PSScriptRoot 'conversion-modules'
if (Test-Path $conversionModulesDir) {
    # Load helper modules first
    $helpersDir = Join-Path $conversionModulesDir 'helpers'
    . (Join-Path $helpersDir 'helpers-xml.ps1')

    # Then load feature modules
    $dataDir = Join-Path $conversionModulesDir 'data'
    . (Join-Path $dataDir 'core' 'core-basic.ps1')
    # ... more modules
}
```

**Benefits of Modular Structure:**

- **Better Organization**: Related functionality grouped in subdirectories
- **Easier Maintenance**: Smaller, focused module files
- **Selective Loading**: Fragments can load only needed modules
- **Clear Dependencies**: Module structure shows relationships
- **Improved Testability**: Modules can be tested independently

### Fragment Template

Every fragment should follow this structure:

```powershell
<#
# XX-fragment-name.ps1
#
Brief description of what this fragment does.
#>

try {
    # Idempotency check - prevent double-loading
    # Use FragmentIdempotency module if available (loaded in main profile)
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'XX-fragment-name') { return }
    }
    else {
        # Fallback to direct variable check
        if ($null -ne (Get-Variable -Name 'FragmentNameLoaded' -Scope Global -ErrorAction SilentlyContinue)) {
            return
        }
    }

    # Fragment implementation
    # Use Set-AgentModeFunction or Set-AgentModeAlias for collision-safe registration
    # Use Test-CachedCommand or Test-HasCommand for command availability checks

    # Mark as loaded using FragmentIdempotency module if available
    if (Get-Command Set-FragmentLoaded -ErrorAction SilentlyContinue) {
        Set-FragmentLoaded -FragmentName 'XX-fragment-name'
    }
    else {
        Set-Variable -Name 'FragmentNameLoaded' -Value $true -Scope Global -Force
    }
}
catch {
    # Error handling - don't throw, allow other fragments to load
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: XX-fragment-name.ps1" -Category 'Fragment'
        } else {
            Write-Verbose "XX-fragment-name.ps1 failed: $($_.Exception.Message)"
        }
    }
}
```

## Refactored Fragments

Several fragments have been refactored into modular subdirectories for better organization and maintainability:

### 00-bootstrap.ps1

The bootstrap fragment has been refactored into focused modules:

```
00-bootstrap.ps1 (thin loader, ~50 lines)
00-bootstrap/
├── GlobalState.ps1           # Global variable initialization
├── TestHasCommand.ps1        # Test-HasCommand (core command detection)
├── CommandCache.ps1         # Test-CachedCommand, cache management
├── AssumedCommands.ps1       # Add-AssumedCommand, Remove-AssumedCommand, Get-AssumedCommands
├── MissingToolWarnings.ps1 # Write-MissingToolWarning, Clear-MissingToolWarnings
├── FragmentWarnings.ps1      # Initialize-FragmentWarningSuppression, Test-FragmentWarningSuppressed
├── FunctionRegistration.ps1 # Set-AgentModeFunction, Set-AgentModeAlias, Register-LazyFunction
└── UserHome.ps1             # Get-UserHome
```

### 23-starship.ps1

The Starship prompt fragment has been refactored into focused modules:

```
23-starship.ps1 (main initialization, ~226 lines)
23-starship/
├── StarshipHelpers.ps1       # Test-StarshipInitialized, Test-PromptNeedsReplacement, Get-StarshipPromptArguments
├── StarshipPrompt.ps1        # New-StarshipPromptFunction
├── StarshipModule.ps1        # Initialize-StarshipModule
├── StarshipInit.ps1          # Invoke-StarshipInitScript
├── StarshipVSCode.ps1        # Update-VSCodePrompt
└── SmartPrompt.ps1           # Initialize-SmartPrompt (complete fallback prompt)
```

### 07-system.ps1

The system utilities fragment has been refactored into category-based modules:

```
07-system.ps1 (thin loader, ~60 lines)
07-system/
├── FileOperations.ps1    # touch, mkdir, rm, cp, mv, find (search)
├── SystemInfo.ps1        # df, htop, which
├── NetworkOperations.ps1 # ptest, dns, rest, web, ports
├── ArchiveOperations.ps1 # zip, unzip
├── EditorAliases.ps1     # vim, vi
└── TextSearch.ps1        # grep (Find-String, pgrep)
```

### 02-files.ps1

The files fragment includes extracted modules:

```
02-files.ps1 (main loader, ~425 lines - mostly module loading)
02-files/
└── LaTeXDetection.ps1    # Test-DocumentLatexEngineAvailable, Ensure-DocumentLatexEngine
```

### conversion-modules/data/core/core-encoding.ps1

The encoding conversion module has been refactored into format-specific sub-modules:

```
core-encoding.ps1 (thin loader, ~60 lines)
core/
├── core-encoding-roman.ps1    # Roman numeral conversions (16 functions)
├── core-encoding-modhex.ps1    # ModHex conversions (16 functions)
├── core-encoding-ascii.ps1     # ASCII conversions (8 functions)
├── core-encoding-hex.ps1        # Hex conversions (15 functions)
├── core-encoding-binary.ps1     # Binary conversions (16 functions)
├── core-encoding-numeric.ps1   # Octal/Decimal conversions (30 functions)
├── core-encoding-base32.ps1    # Base32 conversions (16 functions)
└── core-encoding-url.ps1       # URL/Percent encoding conversions (16 functions)
```

**Benefits of Refactoring:**

- **Reduced complexity**: Main files reduced from 600-2400 lines to 50-226 lines
- **Better organization**: Related functionality grouped in focused modules
- **Easier maintenance**: Smaller files are easier to understand and modify
- **Improved testability**: Modules can be tested independently
- **Clear separation of concerns**: Each module has a single, well-defined responsibility

## Bootstrap Helpers

`00-bootstrap.ps1` (now a thin loader) provides essential helpers available to all fragments through its sub-modules:

### Set-AgentModeFunction

Creates functions without overwriting existing commands:

```powershell
Set-AgentModeFunction -Name 'MyFunc' -Body { Write-Output "Hello" }
```

**Features:**

- Checks for existing commands before creating
- Uses Function: provider for efficient registration
- Supports `-ReturnScriptBlock` for programmatic use

### Set-AgentModeAlias

Creates aliases or function wrappers without overwriting:

```powershell
Set-AgentModeAlias -Name 'gs' -Target 'git status'
```

**Features:**

- Falls back to function wrapper if alias creation fails
- Collision-safe (won't overwrite existing commands)

### Test-CachedCommand

Fast command existence check with caching and TTL:

```powershell
if (Test-CachedCommand 'docker') {
    # configure docker helpers
}
```

**Features:**

- Caches results for performance
- 5-minute TTL (configurable) to handle commands installed after profile load
- Avoids repeated `Get-Command` calls

### Test-HasCommand

Provider-first command check to avoid module autoload:

```powershell
if (Test-HasCommand 'git') {
    # git is available
}
```

**Features:**

- Fast provider checks first (Function:, Alias:)
- Falls back to cached or direct command testing
- Avoids triggering module autoload/discovery

### Register-LazyFunction

Helper for lazy-loading functions that initialize on first use:

```powershell
Register-LazyFunction -Name 'Invoke-GitClone' -Initializer { Ensure-GitHelper } -Alias 'gcl'
```

**Features:**

- Creates stub that calls initializer on first invocation
- Replaces stub with actual function after initialization
- Reduces code duplication for lazy loading patterns

### Platform Detection Helpers

Cross-platform compatibility helpers:

```powershell
Test-IsWindows  # Returns $true on Windows
Test-IsLinux    # Returns $true on Linux
Test-IsMacOS    # Returns $true on macOS
Get-UserHome    # Returns home directory (cross-platform)
```

## Lazy Loading Patterns

### Pattern 1: Enable-\* Functions

Heavy initialization deferred behind `Enable-*` functions:

```powershell
# In fragment: register enabler function only
Set-AgentModeFunction -Name 'Enable-MyTool' -Body {
    # Expensive work happens here when user calls Enable-MyTool
    Import-Module MyExpensiveModule
    Set-AgentModeAlias -Name 'mt' -Target 'mytool'
}
```

### Pattern 2: Register-LazyFunction

For functions that need lazy initialization:

```powershell
# Define the actual function in an Ensure-* function
function Ensure-MyHelper {
    if ($script:__MyHelperInitialized) { return }
    $script:__MyHelperInitialized = $true
    Set-AgentModeFunction -Name 'Invoke-MyHelper' -Body { # actual implementation }
}

# Register lazy stub
Register-LazyFunction -Name 'Invoke-MyHelper' -Initializer { Ensure-MyHelper } -Alias 'mh'
```

### Pattern 3: Lazy Bulk Initializer

For multiple related functions:

```powershell
function Ensure-FileNavigation {
    if ($script:__FileNavInitialized) { return }
    $script:__FileNavInitialized = $true

    # Define all functions at once
    Set-AgentModeFunction -Name 'Set-LocationDesktop' -Body { ... }
    Set-AgentModeFunction -Name 'Set-LocationDownloads' -Body { ... }
}

# Create lazy stubs
function Set-LocationDesktop {
    if (-not (Test-Path Function:\Set-LocationDesktop)) { Ensure-FileNavigation }
    & (Get-Item Function:\Set-LocationDesktop).ScriptBlock.InvokeReturnAsIs($args)
}
```

## Error Handling Strategy

### Fragment-Level Error Handling

All fragments should wrap their code in try-catch:

```powershell
try {
    # Fragment code
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        Write-ProfileError -ErrorRecord $_ -Context "Fragment: XX-name" -Category 'Fragment'
    }
    # Don't throw - allow profile to continue loading
}
```

### Global Error Handler

`72-error-handling.ps1` provides:

- `Write-ProfileError`: Enhanced error logging with context
- `Invoke-ProfileErrorHandler`: Global error handler with recovery suggestions
- `Invoke-SafeFragmentLoad`: Fragment loading with retry logic

### Error Categories

- **Profile**: Main profile loader errors
- **Fragment**: Fragment loading errors
- **Command**: Command execution errors
- **Network**: Network-related errors
- **System**: System-level errors

## Performance Considerations

### Startup Performance

1. **Lazy Loading**: Defer expensive operations until needed
2. **Provider-First Checks**: Use `Test-Path Function:\Name` to avoid module autoload
3. **Cached Commands**: Use `Test-CachedCommand` to avoid repeated `Get-Command` calls
4. **No Side Effects at Load**: Keep fragment dot-sourcing fast

### Runtime Performance

1. **Command Cache TTL**: 5-minute expiration handles commands installed after profile load
2. **Idempotency Checks**: Fast variable checks prevent redundant work
3. **Efficient Path Operations**: Use `Join-Path` and platform-appropriate separators

### Benchmarking

Use `scripts/utils/benchmark-startup.ps1` to measure profile load time:

```powershell
pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -Iterations 30
```

## Cross-Platform Considerations

### Path Handling

- Use `Join-Path` instead of string concatenation
- Use `[System.IO.Path]::PathSeparator` for PATH manipulation
- Use `Get-UserHome` instead of `$env:USERPROFILE`

### Platform-Specific Code

Wrap platform-specific code in checks:

```powershell
if (Test-IsWindows) {
    # Windows-specific code (e.g., registry operations)
} else {
    # Unix-specific code or fallback
}
```

### Common Patterns

```powershell
# Cross-platform home directory
$homeDir = Get-UserHome

# Cross-platform PATH separator
$pathSeparator = [System.IO.Path]::PathSeparator

# Platform-aware path construction
$configDir = Join-Path $homeDir '.config' 'myapp'
```

## Extension Points

### Adding New Fragments

1. Use `scripts/utils/fragment/new-fragment.ps1` to create template
2. Choose appropriate number prefix (00-99)
3. Follow fragment structure template
4. Document functions in fragment README
5. Test idempotency (safe to reload)

### Adding New Modules

When adding functionality that belongs in a module subdirectory:

1. **Identify the appropriate subdirectory** (or create new one if needed)
2. **Create module file** in the subdirectory (e.g., `profile.d/conversion-modules/data/core-basic.ps1`)
3. **Update parent fragment** to load the module (e.g., `02-files.ps1` for conversion modules)
4. **Follow module conventions**:
   - Use `Set-AgentModeFunction` for function registration
   - Guard external tool calls with `Test-CachedCommand`
   - Include error handling for module loading
   - Document functions with comment-based help
5. **Test module loading** and ensure idempotency

### Adding New Helpers

1. Add to `00-bootstrap.ps1` if used by multiple fragments
2. Add to specific fragment if fragment-specific
3. Use collision-safe registration (`Set-AgentModeFunction`)
4. Document with comment-based help
5. Export in fragment README

### Customizing Behavior

- **Disable fragments**: Edit `.profile-fragments.json` or use `Disable-ProfileFragment`
- **Debug mode**: Set `$env:PS_PROFILE_DEBUG=1` (basic), `2` (verbose), or `3` (performance profiling)
- **Batch loading**: Set `$env:PS_PROFILE_BATCH_LOAD=1` or configure in `.profile-fragments.json`
- **Environment-specific sets**: Set `$env:PS_PROFILE_ENVIRONMENT='minimal'` and configure in `.profile-fragments.json`
- **Load order override**: Configure `loadOrder` in `.profile-fragments.json`

### Enhanced Configuration

The `.profile-fragments.json` file supports advanced configuration:

```json
{
  "disabled": ["11-git"],
  "loadOrder": ["00-bootstrap", "01-env", "05-utilities"],
  "environments": {
    "minimal": ["00-bootstrap", "01-env"],
    "development": ["00-bootstrap", "01-env", "11-git", "30-dev-tools"]
  },
  "featureFlags": {
    "enableAdvancedFeatures": true
  },
  "performance": {
    "batchLoad": true,
    "maxFragmentTime": 500
  }
}
```

**Environment-Specific Loading:**

```powershell
$env:PS_PROFILE_ENVIRONMENT = 'minimal'
. $PROFILE
```

## Fragment Dependencies

Fragments can declare explicit dependencies, which are automatically resolved during loading:

### Declaring Dependencies

Fragments can declare dependencies in their header comments using either format:

```powershell
#Requires -Fragment '00-bootstrap'
#Requires -Fragment '01-env'
```

Or using a comment line:

```powershell
# Dependencies: 00-bootstrap, 01-env
```

### Dependency Management Functions

Available from `FragmentLoading.psm1` module (imported in main profile):

- `Get-FragmentDependencies` - Parses dependencies from fragment headers (with caching)
- `Test-FragmentDependencies` - Validates that all dependencies are satisfied
- `Get-FragmentLoadOrder` - Calculates optimal load order using topological sort
- `Get-FragmentTiers` - Groups fragments by tier for batch loading

**Performance Note:** `Get-FragmentDependencies` implements intelligent caching:

- Dependencies are parsed once per file and cached with file modification times
- Cache automatically invalidates when fragment files are modified
- Reduces file I/O and parsing overhead, especially for profiles with many fragments

### Automatic Load Order

The profile loader automatically:

1. Parses dependencies from all fragments (using cached results when available)
2. Validates that dependencies exist and are enabled
3. Sorts fragments topologically to satisfy dependencies
4. Detects and warns about circular dependencies
5. Falls back to lexical order if dependency resolution fails

### Configuration Override

Load order can be overridden via `.profile-fragments.json`:

```json
{
  "loadOrder": ["00-bootstrap", "01-env", "05-utilities"]
}
```

When `loadOrder` is specified, fragments are loaded in that order, with remaining fragments appended in lexical order.

## Security Considerations

### Path Validation

Use `Test-SafePath` to validate user-provided paths:

```powershell
if (Test-SafePath -Path $userPath -BasePath $homeDir) {
    # Safe to use
}
```

### Command Execution

- Validate command availability before execution
- Use parameter validation for user input
- Avoid `Invoke-Expression` with user input

## Version Tracking

Profile version information is tracked with lazy loading to avoid blocking startup:

- `$global:PSProfileVersion` - Profile version string (set immediately, e.g., '1.0.0')
- `$global:PSProfileGitCommit` - Git commit hash (calculated lazily on first access)
- `$global:PSProfileGitCommitGetter` - Lazy getter function for commit hash

The git commit hash is only calculated when accessed (e.g., in debug mode), avoiding the overhead of spawning a git subprocess during profile startup.

Profile version information is available via:

```powershell
$global:PSProfileVersion    # Version string (e.g., '1.0.0')
$global:PSProfileGitCommit  # Git commit hash (if in git repo, calculated lazily)
```

Displayed in debug mode on profile load (triggers lazy calculation if not already done).

## Contributing

See `CONTRIBUTING.md` for:

- Development guidelines
- Code standards
- Testing requirements
- Pull request process

## Related Documentation

- `README.md`: Quick start and overview
- `PROFILE_README.md`: Detailed technical guide
- `CONTRIBUTING.md`: Development guidelines
- `CHANGES_SUMMARY.md`: Recent improvements
- `AGENTS.md`: AI coding assistant guidance
- `WARP.md`: WARP terminal guidance
