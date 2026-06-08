# PowerShell Profile

[![Validate PowerShell Profile](https://github.com/bolens/ps-profile/actions/workflows/validate-profile.yml/badge.svg)](https://github.com/bolens/ps-profile/actions/workflows/validate-profile.yml)
[![Commit message check](https://github.com/bolens/ps-profile/actions/workflows/commit-message-check.yml/badge.svg)](https://github.com/bolens/ps-profile/actions/workflows/commit-message-check.yml)

> **⚠️ WARNING: This project is under active development and may be unstable at any time.**
>
> Breaking changes, incomplete features, and bugs that prevent normal operation can occur without notice. Use at your own risk. Pin a commit if you rely on it, and expect to tune fragments for your environment.

A modular, cross-platform PowerShell profile that turns your shell into a lazy-loaded toolkit for daily development work. Functionality lives in **130+ fragments** under `profile.d/`—each focused on one concern (Git, containers, a language runtime, a cloud CLI, a conversion pipeline, and so on)—and loads only when you need it.

## What This Project Does

This is not a minimal prompt-and-alias dotfile. It is a **maintainable profile framework** built around three ideas:

1. **Modular fragments** — Each feature area is a small, idempotent script in `profile.d/` with explicit dependencies, environment presets, and optional disable flags via `.profile-fragments.json`.
2. **Fast startup** — Expensive work is deferred behind `Enable-*` helpers, command-existence caches, and optional batch/parallel loading so interactive sessions stay responsive.
3. **On-demand command access** — Functions and aliases register in a fragment command registry so commands can load their fragment automatically (including from `-NoProfile` sessions and generated standalone wrappers). See [docs/guides/FRAGMENT_COMMAND_ACCESS.md](docs/guides/FRAGMENT_COMMAND_ACCESS.md).

In practice the profile bundles helpers for:

- **Development workflows** — Git, modern CLI tools, language runtimes (Go, Rust, Python, Java, Node, and more), build/test runners, and editor integrations
- **Cloud and infrastructure** — AWS, Azure, GCP, Kubernetes, Terraform, Ansible, and related tooling
- **Containers** — Docker/Podman helpers with auto-detection
- **Data and document conversion** — JSON/YAML/CSV/XML, columnar and binary formats, Markdown/LaTeX notes, media transforms, ISBN/bibliography utilities, QR codes, and related pipelines under `profile.d/conversion-modules/`
- **Shell quality of life** — PSReadLine, oh-my-posh/Starship prompts, history, diagnostics, and system monitoring

The repo also ships the **tooling that keeps the profile maintainable**: Pester unit/integration/performance tests, PSScriptAnalyzer linting, startup benchmarks, auto-generated API docs (`docs/api/`), and 48+ quality tasks via Task/Just/Make/npm.

**Current scale:** see [docs/api/README.md](docs/api/README.md) for live function and alias counts (currently ~1,500 of each).

## Quick Start

Clone this repository to your PowerShell profile path, then reload:

```powershell
# Windows (PowerShell 7+)
git clone https://github.com/bolens/ps-profile.git $HOME\Documents\PowerShell

# Linux / macOS
git clone https://github.com/bolens/ps-profile.git ~/.config/powershell

# Reload profile
. $PROFILE
```

Optional: load a slimmer preset before sourcing (see [PROFILE_README.md](PROFILE_README.md#fragment-configuration)):

```powershell
$env:PS_PROFILE_ENVIRONMENT = 'minimal'   # or development, cloud, ci, …
. $PROFILE
```

## Features

- **Modular fragments** — 130+ focused scripts in `profile.d/` with dependency-aware load order and organized sub-modules
- **Performance optimized** — Lazy loading, deferred initialization, fragment caching, and startup benchmarks
- **On-demand commands** — Fragment command registry, auto-loading dispatcher, and optional standalone wrappers
- **Cross-platform** — Windows, Linux, and macOS with platform-aware tool detection
- **Data & document tooling** — Broad conversion helpers under `conversion-modules/` (data, document, media, dev-tools)
- **Cloud & containers** — AWS/Azure/GCP/Kubernetes/Terraform helpers plus Docker/Podman integrations
- **Developer shell** — Git workflows, modern CLI aliases, language-specific fragments, prompts (oh-my-posh/Starship)
- **Tested & documented** — Pester suites, CI validation, auto-generated API reference, and contributor guides

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

See [docs/guides/TESTING.md](docs/guides/TESTING.md) for the full runner reference (flags, batch scripts, exit codes). The test runner includes advanced features for robust testing:

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
- [docs/guides/TESTING.md](docs/guides/TESTING.md) — Primary testing guide (structure, runner flags, batch scripts)
- [docs/guides/DEVELOPMENT.md](docs/guides/DEVELOPMENT.md) — Setup, workflow, and advanced testing
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
│   │   └── format/                    # Formatting tools (including qrcode/)
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
│   ├── lib/                           # Shared script modules (68+ modules, modular library)
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
