# Scripts Utils Directory

This directory contains utility scripts organized by category.

## Directory Structure

```
scripts/utils/
├── code-quality/      # Code quality and testing scripts
│   ├── run-lint.ps1
│   ├── run-format.ps1
│   ├── run-markdownlint.ps1
│   ├── run-pester.ps1
│   └── spellcheck.ps1
├── metrics/           # Metrics and performance scripts
│   ├── benchmark-startup.ps1
│   ├── collect-code-metrics.ps1
│   ├── export-metrics.ps1
│   └── find-duplicate-functions.ps1
├── docs/              # Documentation generation scripts
│   ├── generate-changelog.ps1
│   ├── generate-docs.ps1
│   └── generate-fragment-readmes.ps1
├── dependencies/      # Dependency management scripts
│   ├── check-module-updates.ps1
│   └── validate-dependencies.ps1
├── security/          # Security scanning scripts
│   └── run-security-scan.ps1
├── release/           # Release management scripts
│   └── create-release.ps1
├── fragment/          # Fragment management scripts
│   └── new-fragment.ps1
└── init-wrangler-config.ps1  # Miscellaneous utilities
```

## Script Categories

### Code Quality (`code-quality/`)

Scripts for maintaining code quality:

- **run-lint.ps1** - Run PSScriptAnalyzer linting
- **run-format.ps1** - Format PowerShell code
- **run-markdownlint.ps1** - Lint Markdown files
- **run-pester.ps1** - Run Pester tests
- **spellcheck.ps1** - Spell check files

### Metrics (`metrics/`)

Scripts for collecting and analyzing metrics:

- **benchmark-startup.ps1** - Benchmark profile startup performance
- **collect-code-metrics.ps1** - Collect code metrics
- **export-metrics.ps1** - Export metrics to various formats
- **find-duplicate-functions.ps1** - Find duplicate function definitions

### Documentation (`docs/`)

Scripts for generating documentation:

- **generate-changelog.ps1** - Generate changelog from git commits
- **generate-docs.ps1** - Generate API documentation
- **generate-fragment-readmes.ps1** - Generate README files for fragments

### Dependencies (`dependencies/`)

Scripts for managing dependencies:

- **check-module-updates.ps1** - Check for PowerShell module updates
- **validate-dependencies.ps1** - Validate and install dependencies

### Security (`security/`)

Scripts for security scanning:

- **run-security-scan.ps1** - Run security scans for secrets and vulnerabilities

### Release (`release/`)

Scripts for release management:

- **create-release.ps1** - Create release notes and tags

### Fragment (`fragment/`)

Scripts for managing profile fragments:

- **new-fragment.ps1** - Create new profile fragments

## Import Pattern

Scripts in subdirectories should import library modules using the modular import pattern:

```powershell
# Import ModuleImport first (bootstrap) - works from any scripts/ subdirectory
$moduleImportPath = Join-Path (Split-Path -Parent (Split-Path -Parent $PSScriptRoot)) 'lib' 'ModuleImport.psm1'
Import-Module $moduleImportPath -DisableNameChecking -ErrorAction Stop

# Import specific modules using Import-LibModule (handles path resolution automatically)
Import-LibModule -ModuleName 'ExitCodes' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'PathResolution' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Logging' -ScriptPath $PSScriptRoot -DisableNameChecking
Import-LibModule -ModuleName 'Module' -ScriptPath $PSScriptRoot -DisableNameChecking
```

This pattern works for scripts in any subdirectory of `scripts/utils/` and automatically handles path resolution.

**Available Library Modules:**

- `ModuleImport.psm1` - Module import helper (import this first)
- `ExitCodes.psm1` - Exit code constants
- `PathResolution.psm1` - Path resolution utilities
- `Logging.psm1` - Logging utilities
- `Module.psm1` - Module management
- `Command.psm1` - Command utilities
- `FileSystem.psm1` - File system operations
- And many more (see `scripts/lib/` directory)

## Usage

All scripts can be run from the repository root:

```powershell
# Code quality
pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1
pwsh -NoProfile -File scripts/utils/code-quality/run-format.ps1

# Metrics
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1

# Documentation
pwsh -NoProfile -File scripts/utils/docs/generate-docs.ps1

# Dependencies
pwsh -NoProfile -File scripts/utils/dependencies/check-module-updates.ps1

# Security
pwsh -NoProfile -File scripts/utils/security/run-security-scan.ps1
```

See `scripts/examples/README.md` for more detailed usage examples.
