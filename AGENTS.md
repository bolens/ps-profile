# AGENTS.md

This file provides guidance for AI coding assistants (Claude, Cursor, GitHub Copilot, etc.) when working with this PowerShell profile repository.

## Quick Start for AI Assistants

This is a **modular PowerShell profile** with:

- **110+ functions** and **100+ aliases** (see `docs/api/README.md` for current counts)
- **Comprehensive testing** with Pester (unit, integration, performance)
- **Strict code quality** standards (PSScriptAnalyzer, formatting, security scanning)
- **Performance optimized** with lazy loading, caching, and deferred initialization
- **Cross-platform** support (Windows, Linux, macOS)

## Project Structure

```
├── Microsoft.PowerShell_profile.ps1  # Main profile loader (keep minimal)
├── profile.d/                         # Modular fragments (00-99)
│   ├── 00-bootstrap.ps1               # Core helpers (Set-AgentModeFunction, etc.)
│   ├── 01-env.ps1                     # Environment configuration
│   ├── 02-files.ps1                   # File utilities (loads modules)
│   ├── 05-utilities.ps1               # General utilities (loads modules)
│   ├── 06-oh-my-posh.ps1              # Prompt framework
│   ├── 11-git.ps1                     # Git helpers (loads modules)
│   ├── 22-containers.ps1              # Container utilities (loads modules)
│   ├── [other numbered fragments]     # Additional feature fragments
│   ├── cli-modules/                   # Modern CLI tool modules
│   ├── container-modules/             # Container helper modules
│   ├── conversion-modules/            # Data/document/media conversion modules
│   │   ├── data/                      # Data format conversions (binary, columnar, core, scientific, structured)
│   │   ├── document/                  # Document format conversions
│   │   ├── helpers/                   # Conversion helper utilities
│   │   └── media/                     # Media format conversions (including color conversions)
│   ├── dev-tools-modules/             # Development tool modules
│   │   ├── build/                     # Build tools and testing frameworks
│   │   ├── crypto/                    # Cryptographic utilities
│   │   ├── data/                      # Data manipulation tools
│   │   ├── encoding/                  # Encoding utilities
│   │   └── format/                    # Formatting tools (including qrcode/)
│   ├── diagnostics-modules/          # Diagnostic and monitoring modules
│   │   ├── core/                      # Core diagnostics
│   │   └── monitoring/                # System monitoring
│   ├── files-modules/                 # File operation modules
│   │   ├── inspection/                # File inspection utilities
│   │   └── navigation/                # File navigation helpers
│   ├── git-modules/                   # Git integration modules
│   │   ├── core/                      # Core Git operations
│   │   └── integrations/              # Git service integrations
│   └── utilities-modules/             # Utility function modules
│       ├── data/                      # Data utilities
│       ├── filesystem/                # Filesystem utilities
│       ├── history/                   # Command history utilities
│       ├── network/                   # Network utilities
│       └── system/                    # System utilities
├── scripts/                           # Validation & utilities
│   ├── lib/                           # Shared utility modules (ALWAYS use these)
│   │   ├── ModuleImport.psm1          # Module import helper (import first)
│   │   ├── ExitCodes.psm1             # Exit code constants
│   │   ├── PathResolution.psm1        # Path resolution utilities
│   │   ├── Logging.psm1               # Logging utilities
│   │   ├── FragmentConfig.psm1        # Fragment configuration
│   │   ├── FragmentLoading.psm1       # Fragment dependency resolution
│   │   └── [many more specialized modules]
│   ├── checks/                        # Validation scripts
│   └── utils/                         # Helper scripts by category
│       ├── code-quality/              # Linting, formatting, testing
│       │   └── modules/                # Test runner modules
│       ├── metrics/                   # Performance and code metrics
│       ├── docs/                      # Documentation generation
│       │   └── modules/                # Documentation modules
│       ├── dependencies/              # Dependency management
│       │   └── modules/                # Dependency modules
│       ├── security/                  # Security scanning
│       │   └── modules/                # Security modules
│       └── fragment/                  # Fragment management
├── tests/                             # Pester tests
│   ├── unit/                          # Unit tests
│   ├── integration/                   # Integration tests (domain-organized)
│   │   ├── bootstrap/                 # Bootstrap tests
│   │   ├── conversion/                # Conversion utilities (data/document/media)
│   │   ├── filesystem/                # Filesystem utilities
│   │   ├── fragments/                 # Fragment management
│   │   ├── profile/                   # Profile loading
│   │   ├── tools/                     # Development tools
│   │   ├── system/                    # System utilities
│   │   ├── terminal/                  # Terminal/prompt tools
│   │   ├── test-runner/               # Test runner tests
│   │   ├── utilities/                 # Utility functions
│   │   ├── cross-platform/            # Cross-platform tests
│   │   └── error-handling/            # Error handling
│   └── performance/                   # Performance tests
└── docs/                              # Auto-generated API docs
```

## Critical Rules for AI Assistants

### 1. Always Use Modular Library Imports

**NEVER** write utility scripts without importing the required modules from `scripts/lib/`:

```powershell
# Import ModuleImport first (bootstrap)
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import specific modules using Import-LibModule
# Note: Import-LibModule automatically resolves subdirectories (core/, fragment/, path/, etc.)
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking

# Use shared functions
$repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
```

**Available Library Modules:**

The `scripts/lib/` directory is organized into category-based subdirectories. Use `Import-LibModule` to import modules - it automatically resolves subdirectories:

- **Core modules** (`core/`): `ExitCodes.psm1`, `Logging.psm1`, `Platform.psm1`
- **Fragment modules** (`fragment/`): `FragmentConfig.psm1`, `FragmentLoading.psm1`, `FragmentIdempotency.psm1`, `FragmentErrorHandling.psm1`
- **Path modules** (`path/`): `PathResolution.psm1`, `PathUtilities.psm1`, `PathValidation.psm1`
- **File modules** (`file/`): `FileContent.psm1`, `FileFiltering.psm1`, `FileSystem.psm1`
- **Runtime modules** (`runtime/`): `Module.psm1`, `NodeJs.psm1`, `PowerShellDetection.psm1`, `Python.psm1`, `ScoopDetection.psm1`
- **Utilities** (`utilities/`): `Cache.psm1`, `Command.psm1`, `Collections.psm1`, `DataFile.psm1`, `JsonUtilities.psm1`, `RegexUtilities.psm1`, `StringSimilarity.psm1`
- **Metrics** (`metrics/`): `CodeMetrics.psm1`, `CodeQualityScore.psm1`, `MetricsHistory.psm1`, `MetricsSnapshot.psm1`, `MetricsTrendAnalysis.psm1`
- **Performance** (`performance/`): `PerformanceAggregation.psm1`, `PerformanceMeasurement.psm1`, `PerformanceRegression.psm1`
- **Code Analysis** (`code-analysis/`): `AstParsing.psm1`, `CodeSimilarityDetection.psm1`, `CommentHelp.psm1`, `TestCoverage.psm1`
- **Parallel** (`parallel/`): `Parallel.psm1`
- **Module Import Helper** (root): `ModuleImport.psm1` - Provides `Import-LibModule`, `Get-LibPath`, etc.

**Note**: When using `Import-LibModule`, you don't need to specify subdirectory paths - it automatically resolves them. Only use direct paths if you're importing modules without using `Import-LibModule`.

### 2. Exit Code Standards

**NEVER use direct `exit` calls**. Always use `Exit-WithCode`:

```powershell
# ❌ WRONG
exit 1

# ✅ CORRECT
Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Validation failed"
```

**Standard Exit Codes:**

- `$EXIT_SUCCESS` (0) - Success
- `$EXIT_VALIDATION_FAILURE` (1) - Expected validation failure
- `$EXIT_SETUP_ERROR` (2) - Setup/configuration error
- `$EXIT_RUNTIME_ERROR` (3) - Runtime error

### 3. Fragment Development Rules

All fragments in `profile.d/` MUST be:

**Idempotent** - Safe to source multiple times:

```powershell
# Use bootstrap helpers
Set-AgentModeFunction -Name 'MyFunc' -Body { Write-Output "Hello" }
Set-AgentModeAlias -Name 'gs' -Target 'git status'

# Or guard with provider checks
if (-not (Test-Path Function:\MyFunc)) {
    function MyFunc { ... }
}
```

**Lazy Loading** - Defer expensive operations:

```powershell
# Register enabler function only
Set-AgentModeFunction -Name 'Enable-MyTool' -Body {
    # Expensive work happens here when user calls Enable-MyTool
    Import-Module MyExpensiveModule
    Set-AgentModeAlias -Name 'mt' -Target 'mytool'
}
```

**Note:** The profile loader implements several performance optimizations:

- Git commit hash calculation is lazy (only runs when accessed)
- Fragment file lists are cached to avoid duplicate `Get-ChildItem` calls
- Fragment dependency parsing is cached with file modification time tracking
- Module path existence checks are cached to reduce `Test-Path` operations
- See `ARCHITECTURE.md` and `PROFILE_README.md` for detailed information

**Guard External Tools**:

```powershell
if (Test-CachedCommand 'docker') {
    # Configure docker helpers
}
```

### 4. Testing Requirements

**ALWAYS write tests** for new functionality:

```powershell
# ⚠️ CRITICAL: Use analyze-coverage.ps1 for test execution and coverage analysis
# This script runs non-interactively, generates comprehensive coverage reports, and identifies coverage gaps

# Analyze coverage for a specific file or directory
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/00-bootstrap

# Analyze coverage for multiple paths
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/00-bootstrap,profile.d/11-git.ps1

# The script automatically:
# - Matches test files to source files based on naming conventions
# - Runs Pester tests with coverage analysis
# - Reports per-file coverage percentages
# - Identifies files with < 80% coverage
# - Generates JSON coverage reports

# For legacy/test purposes only (use analyze-coverage.ps1 instead):
# pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Unit
```

**Test file naming:**

- Unit tests: `tests/unit/*.tests.ps1`
- Integration tests: `tests/integration/**/*.tests.ps1` (recursive discovery, domain-organized)
- Performance tests: `tests/performance/*.tests.ps1`

### 5. Code Quality Standards

**Before committing, ALWAYS run:**

```powershell
# Full quality check (recommended)
task quality-check    # or: just quality-check, make quality-check, npm run quality-check

# Or individual checks
task format          # Format code (or: just format, make format, npm run format)
task lint            # PSScriptAnalyzer (or: just lint, make lint, npm run lint)
task test            # Run tests (or: just test, make test, npm run test)
task spellcheck      # Spellcheck (or: just spellcheck, make spellcheck, npm run spellcheck)
task markdownlint    # Markdown linting (or: just markdownlint, make markdownlint, npm run markdownlint)
```

**PSScriptAnalyzer Rules:**

- No unapproved verbs
- Proper parameter validation
- Comment-based help for functions
- See `PSScriptAnalyzerSettings.psd1` for configuration

### 6. Documentation Standards

**All functions MUST have comment-based help:**

```powershell
function Get-Example {
    <#
    .SYNOPSIS
        Brief description.

    .DESCRIPTION
        Detailed description.

    .PARAMETER Name
        Parameter description.

    .EXAMPLE
        Get-Example -Name "test"

        Example usage.

    .OUTPUTS
        System.String
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param(
        [Parameter(Mandatory)]
        [string]$Name
    )

    # Function body
}
```

**Generate documentation:**

```powershell
task generate-docs              # API documentation (or: just generate-docs, make generate-docs, npm run generate-docs)
task generate-fragment-readmes  # Fragment READMEs (or: just generate-fragment-readmes, make generate-fragment-readmes, npm run generate-fragment-readmes)
```

## Common Development Tasks

### Running Tests

```powershell
# All tests (works with: task, just, make, npm run)
task test

# Specific suite
task test-unit
task test-integration
task test-performance

# ⚠️ CRITICAL: Use analyze-coverage.ps1 for test execution and coverage analysis
# This script runs non-interactively, generates comprehensive coverage reports, and identifies coverage gaps
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/00-bootstrap

# Analyze coverage for specific file or directory
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/22-containers.ps1

# Analyze coverage for multiple paths
pwsh -NoProfile -File scripts/utils/code-quality/analyze-coverage.ps1 -Path profile.d/00-bootstrap,profile.d/11-git.ps1

# Advanced features (direct script execution - use analyze-coverage.ps1 instead)
# pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -MaxRetries 3 -TrackPerformance
```

**Important**: Always use `analyze-coverage.ps1` for test execution during development. It provides:

- Non-interactive execution (no prompts)
- Automatic test file matching
- Per-file coverage reporting
- Coverage gap identification
- JSON report generation

### Validation

```powershell
# Full validation (works with: task, just, make, npm run)
task validate

# Individual checks
task format
task lint
task security-scan
task check-idempotency
```

### Performance

```powershell
# Benchmark startup
task benchmark

# Update baseline
task update-baseline
```

## Fragment Loading Order

Fragments use numeric prefixes:

- **00-09**: Core bootstrap, environment, helpers
- **10-19**: Terminal configuration (PSReadLine, prompts, Git)
- **20-29**: Container engines, cloud tools
- **30-39**: Development tools and aliases
- **40-69**: Language-specific tools
- **70-79**: Advanced features

## Modular Subdirectory Structure

Many fragments have been refactored to use organized subdirectories. Main fragments (e.g., `02-files.ps1`, `05-utilities.ps1`) load related modules from subdirectories:

- **`cli-modules/`** - Modern CLI tool integrations
- **`container-modules/`** - Container helper modules
- **`conversion-modules/`** - Data/document/media format conversions
- **`dev-tools-modules/`** - Development tool integrations
- **`diagnostics-modules/`** - Diagnostic and monitoring modules
- **`files-modules/`** - File operation modules
- **`git-modules/`** - Git integration modules
- **`utilities-modules/`** - Utility function modules

When working with modules:

- Modules are dot-sourced by parent fragments
- Use `Set-AgentModeFunction` for function registration
- Include error handling for module loading
- Ensure modules are idempotent

## Bootstrap Helpers

Available to all fragments from `00-bootstrap.ps1`:

### Set-AgentModeFunction

Creates functions without overwriting:

```powershell
Set-AgentModeFunction -Name 'MyFunc' -Body { Write-Output "Hello" }
```

### Set-AgentModeAlias

Creates aliases or function wrappers:

```powershell
Set-AgentModeAlias -Name 'gs' -Target 'git status'
```

### Test-CachedCommand

Fast command existence check with caching:

```powershell
if (Test-CachedCommand 'docker') {
    # Configure docker helpers
}
```

### Register-LazyFunction

Lazy-loading function registration:

```powershell
Register-LazyFunction -Name 'Invoke-GitClone' -Initializer { Ensure-GitHelper } -Alias 'gcl'
```

## Error Handling Patterns

**Always use try-catch for risky operations:**

```powershell
try {
    $repoRoot = Get-RepoRoot -ScriptPath $PSScriptRoot
    Ensure-ModuleAvailable -ModuleName 'PSScriptAnalyzer'
}
catch {
    Exit-WithCode -ExitCode $EXIT_SETUP_ERROR -ErrorRecord $_
}
```

## Commit Message Format

Use [Conventional Commits](https://www.conventionalcommits.org/):

```text
feat(cli): add new command
fix(git): correct branch detection
docs: update README
refactor: simplify bootstrap logic
test: add unit tests for OutputUtils
```

## Debug Mode

Enable debug output:

```powershell
# Basic debug
$env:PS_PROFILE_DEBUG = '1'
$VerbosePreference = 'Continue'

# Performance profiling
$env:PS_PROFILE_DEBUG_TIMINGS = '1'
```

## Key Files to Reference

- **CONTRIBUTING.md** - Detailed contribution guidelines
- **ARCHITECTURE.md** - Technical architecture details
- **PROFILE_README.md** - Comprehensive profile documentation
- **docs/guides/DEVELOPMENT.md** - Developer guide and advanced testing
- **PROFILE_DEBUG.md** - Debugging and instrumentation
- **Taskfile.yml** - Available tasks
- **PSScriptAnalyzerSettings.psd1** - Linter configuration

## Common Pitfalls to Avoid

1. ❌ **Don't use direct `exit` calls** → Use `Exit-WithCode`
2. ❌ **Don't skip module imports** → Always import required modules from scripts/lib/
3. ❌ **Don't make fragments non-idempotent** → Use bootstrap helpers
4. ❌ **Don't add expensive operations at load time** → Use lazy loading
5. ❌ **Don't skip tests** → Write unit tests for all new code
6. ❌ **Don't commit without validation** → Run `task quality-check`
7. ❌ **Don't forget comment-based help** → Document all functions
8. ❌ **Don't hardcode paths** → Use `Get-RepoRoot` and `Join-Path`

## Advanced Features

### Test Runner Capabilities

The test runner (`scripts/utils/code-quality/run-pester.ps1`) supports:

- **Retry logic** for flaky tests
- **Performance monitoring** (memory, CPU tracking)
- **Performance baselining** for regression detection
- **Environment health checks**
- **Detailed analysis and reporting** (HTML, JSON, Markdown)

See `docs/guides/DEVELOPMENT.md` for detailed examples.

### Module Structure

Test runner modules in `scripts/utils/code-quality/modules/`:

- `PesterConfig.psm1` - Configuration management
- `TestDiscovery.psm1` - Test path discovery
- `TestExecution.psm1` - Execution and retry logic
- `TestReporting.psm1` - Analysis and reporting
- `OutputUtils.psm1` - Output sanitization

## CI/CD

GitHub Actions workflows validate on:

- Windows (PowerShell 5.1 & pwsh)
- Linux (pwsh)

Validation includes:

- Format check
- Security scan
- Linting
- Idempotency test
- Spellcheck
- Tests

## Questions?

For detailed information, see:

- [CONTRIBUTING.md](CONTRIBUTING.md) - How to contribute
- [ARCHITECTURE.md](ARCHITECTURE.md) - Technical details
- [docs/guides/DEVELOPMENT.md](docs/guides/DEVELOPMENT.md) - Developer guide
- [WARP.md](WARP.md) - WARP-specific guidance
