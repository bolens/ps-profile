# PowerShell Profile

[![Validate PowerShell Profile](https://github.com/bolens/ps-profile/actions/workflows/validate-profile.yml/badge.svg)](https://github.com/bolens/ps-profile/actions/workflows/validate-profile.yml)
[![Commit message check](https://github.com/bolens/ps-profile/actions/workflows/commit-message-check.yml/badge.svg)](https://github.com/bolens/ps-profile/actions/workflows/commit-message-check.yml)

> **⚠️ WARNING: This project is unstable and may not be working at any given time.**
>
> This repository is under active development and may contain breaking changes, incomplete features, or bugs that prevent normal operation. Use at your own risk.

A modular, performance-optimized PowerShell profile with lazy loading, container helpers, prompt frameworks, and comprehensive validation.

## Quick Start

```powershell
# Clone to PowerShell profile location
git clone https://github.com/bolens/ps-profile.git $HOME\Documents\PowerShell

# Reload profile
. $PROFILE
```

## Features

- **Modular Design**: Small, maintainable fragments in `profile.d/` with organized sub-modules, loaded in dependency-aware order
- **Performance Optimized**: Lazy loading and deferred initialization for fast startup
- **Container Support**: Docker/Podman helpers with auto-detection (`dcu`, `dcd`, `dcl`, etc.)
- **Prompt Frameworks**: oh-my-posh and Starship with lazy initialization
- **Comprehensive Tooling**: 110+ functions, 100+ aliases, validation scripts, benchmarks (see `docs/api/README.md` for current counts)

## Quick Reference

### Development Tasks

This project supports multiple task runners for maximum flexibility. All tasks are available through:

- **Task** (recommended): `task <task-name>` (e.g., `task lint`, `task validate`)
- **Just**: `just <recipe-name>` (e.g., `just lint`, `just validate`)
- **Make**: `make <target>` (e.g., `make lint`, `make validate`)
- **npm/pnpm**: `npm run <script>` or `pnpm run <script>` (e.g., `npm run lint`, `pnpm run validate`)
- **VS Code**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → select a task
- **Sublime Text**: Tools → Build System → "Task: <name>"

**Common Tasks**:

- `validate` - Full validation (format + security + lint + spellcheck + help + idempotency)
- `quality-check` - Comprehensive quality check (format + security + lint + spellcheck + markdownlint + help + tests)
- `format-and-lint` - Format and lint code (common pre-commit workflow)
- `all-docs` - Generate all documentation (API docs + fragment READMEs)
- `test` - Run Pester tests
- `test-unit` - Run the unit test suite only
- `test-integration` - Run the integration test suite only
- `test-performance` - Run the performance test suite only
- `test-coverage` - Run tests with coverage
- `benchmark` - Performance benchmark
- `check-idempotency` - Check fragment idempotency
- `format` - Format code
- `lint` - Lint code
- `pre-commit-checks` - Run pre-commit checks manually

See `Taskfile.yml`, `justfile`, `Makefile`, or `package.json` for all available tasks. All task runners have full parity with 48+ tasks available.

### Testing

```powershell
# Run all tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1

# Run specific test suites
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Unit
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Integration
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Performance

# Run specific tests by name (supports wildcards and "or" syntax)
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TestName "*Edit-Profile*"
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Suite Integration -TestName "*Backup-Profile* or *Convert-*"

# Run tests with coverage
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -Coverage
```

### Advanced Testing Features

The test runner includes advanced features for robust testing:

**New Features:**

- **List Tests** (`-ListTests`) - View available tests without running
- **Failed Only** (`-FailedOnly`) - Re-run only failed tests from last run
- **Git Integration** (`-ChangedFiles`, `-ChangedSince`) - Run tests for changed files
- **Watch Mode** (`-Watch`) - Auto-rerun tests on file changes
- **Test File Patterns** (`-TestFilePattern`) - Filter test files by name pattern
- **Interactive Mode** (`-Interactive`) - Select tests from interactive menu
- **Config Files** (`-ConfigFile`, `-SaveConfig`) - Save/load test configurations
- **Enhanced Statistics** (`-ShowSummaryStats`) - Detailed test statistics
- **Multiple Test Files** - Run multiple files with `-TestFile` or `-Path` (supports arrays)
- **Enhanced Exit Codes** - Granular exit codes for different failure types

```powershell
# Retry logic for flaky tests
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -MaxRetries 3 -RetryOnFailure

# Performance monitoring
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -TrackPerformance -TrackMemory -TrackCPU

# Environment health checks
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -HealthCheck -StrictMode

# Test analysis and reporting
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -AnalyzeResults -ReportFormat HTML -ReportPath "test-report.html"

# Category-based filtering
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -OnlyCategories Unit,Integration

# Performance baselining
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -GenerateBaseline -BaselinePath "baseline.json"
pwsh -NoProfile -File scripts/utils/code-quality/run-pester.ps1 -CompareBaseline -BaselineThreshold 10
```

### Performance

```powershell
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -Iterations 30
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -UpdateBaseline  # Update baseline
```

Performance test thresholds can be tuned with environment variables:

- `PS_PROFILE_MAX_LOAD_MS` (default 6000)
- `PS_PROFILE_MAX_FRAGMENT_MS` (default 500)

### Documentation

- [PROFILE_README.md](PROFILE_README.md) — Comprehensive technical guide
- [CONTRIBUTING.md](CONTRIBUTING.md) — Development and contribution guidelines
- [PROFILE_DEBUG.md](PROFILE_DEBUG.md) — Debugging and instrumentation
- [docs/guides/DEVELOPMENT.md](docs/guides/DEVELOPMENT.md) — Developer guide and advanced testing
- [docs/README.md](docs/README.md) — API documentation (auto-generated)
- [AGENTS.md](AGENTS.md) — AI coding assistant guidance
- [WARP.md](WARP.md) — WARP terminal guidance

## Project Structure

```text
├── Microsoft.PowerShell_profile.ps1   # Main profile loader
├── profile.d/                         # Modular fragments (dependency-aware loading)
│   ├── bootstrap.ps1                  # Registration helpers
│   ├── env.ps1                        # Environment configuration
│   ├── files.ps1                      # File utilities (loads modules)
│   ├── utilities.ps1                  # General utilities (loads modules)
│   ├── git.ps1                        # Git helpers (loads modules)
│   ├── containers.ps1                 # Container utilities (loads modules)
│   ├── [other fragments]              # Additional feature fragments
│   ├── cli-modules/                   # Modern CLI tool modules
│   ├── container-modules/             # Container helper modules
│   ├── conversion-modules/            # Data/document/media conversion modules
│   │   ├── data/                      # Data format conversions
│   │   │   ├── binary/                # Binary formats (Avro, FlatBuffers, Protobuf, Thrift)
│   │   │   ├── columnar/              # Columnar formats (Arrow, Parquet)
│   │   │   ├── core/                  # Core conversions (base64, CSV, JSON, XML, YAML)
│   │   │   ├── scientific/            # Scientific formats (HDF5, NetCDF)
│   │   │   └── structured/            # Structured formats (SuperJSON, TOML, TOON)
│   │   ├── document/                  # Document format conversions
│   │   ├── helpers/                   # Conversion helper utilities
│   │   └── media/                     # Media format conversions (including color conversions)
│   ├── dev-tools-modules/             # Development tool modules
│   │   ├── build/                     # Build tool integrations
│   │   ├── crypto/                    # Cryptographic utilities
│   │   ├── data/                      # Data manipulation tools
│   │   ├── encoding/                  # Encoding utilities
│   │   └── format/                    # Formatting tools
│   │   └── qrcode/                    # QR code generation utilities
│   ├── diagnostics-modules/           # Diagnostic and monitoring modules
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
│   ├── checks/                        # Validation scripts
│   ├── lib/                           # Shared script modules (39 modules, modular library)
│   │   ├── ModuleImport.psm1          # Module import helper
│   │   ├── ExitCodes.psm1             # Exit code constants
│   │   ├── PathResolution.psm1        # Path resolution utilities
│   │   ├── Logging.psm1               # Logging utilities
│   │   ├── FragmentConfig.psm1        # Fragment configuration
│   │   ├── FragmentLoading.psm1       # Fragment dependency resolution
│   │   └── [36 more specialized modules: metrics, performance, code analysis, etc.]
│   ├── utils/                         # Helper scripts (organized by category)
│   │   ├── code-quality/              # Linting, formatting, testing
│   │   │   └── modules/               # Test runner modules
│   │   ├── metrics/                   # Performance and code metrics
│   │   ├── docs/                      # Documentation generation
│   │   │   └── modules/               # Documentation modules
│   │   ├── dependencies/              # Dependency management
│   │   │   └── modules/               # Dependency modules
│   │   ├── security/                  # Security scanning
│   │   │   └── modules/               # Security modules
│   │   ├── release/                   # Release management
│   │   └── fragment/                  # Fragment management
│   ├── templates/                     # Script templates
│   └── examples/                      # Usage examples
└── docs/                              # Documentation
    ├── api/                           # API Reference (auto-generated)
    │   ├── functions/                 # Function documentation
    │   └── aliases/                   # Alias documentation
    ├── fragments/                     # Fragment documentation
    └── guides/                        # Developer guides
```

## License

Open source. See individual files for licensing information.
