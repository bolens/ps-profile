# PowerShell Profile

[![Validate PowerShell Profile](https://github.com/bolens/ps-profile/actions/workflows/validate-profile.yml/badge.svg)](https://github.com/bolens/ps-profile/actions/workflows/validate-profile.yml)
[![Commit message check](https://github.com/bolens/ps-profile/actions/workflows/commit-message-check.yml/badge.svg)](https://github.com/bolens/ps-profile/actions/workflows/commit-message-check.yml)

A modular, performance-optimized PowerShell profile with lazy loading, container helpers, prompt frameworks, and comprehensive validation.

## Quick Start

```powershell
# Clone to PowerShell profile location
git clone https://github.com/bolens/ps-profile.git $HOME\Documents\PowerShell

# Reload profile
. $PROFILE
```

## Features

- **Modular Design**: Small, maintainable fragments in `profile.d/` loaded in lexical order
- **Performance Optimized**: Lazy loading and deferred initialization for fast startup
- **Container Support**: Docker/Podman helpers with auto-detection (`dcu`, `dcd`, `dcl`, etc.)
- **Prompt Frameworks**: oh-my-posh and Starship with lazy initialization
- **Comprehensive Tooling**: 228 functions, 255 aliases, validation scripts, benchmarks

## Quick Reference

### Development Tasks

This project includes VS Code tasks and Taskfile commands for common development workflows.

**VS Code**: Press `Ctrl+Shift+P` → "Tasks: Run Task" → select a task

**Taskfile**: Run `task <task-name>` (e.g., `task lint`, `task validate`)

**Common Tasks**:

- `validate` - Full validation (format + security + lint + spellcheck + help + idempotency)
- `quality-check` - Comprehensive quality check (format + security + lint + spellcheck + markdownlint + help + tests)
- `format-and-lint` - Format and lint code (common pre-commit workflow)
- `all-docs` - Generate all documentation (API docs + fragment READMEs)
- `test` - Run Pester tests
- `test-coverage` - Run tests with coverage
- `benchmark` - Performance benchmark
- `check-idempotency` - Check fragment idempotency
- `format` - Format code
- `lint` - Lint code
- `pre-commit-checks` - Run pre-commit checks manually

See `.vscode/tasks.json` or `Taskfile.yml` for all available tasks.

### Validation

```powershell
pwsh -NoProfile -File scripts/checks/validate-profile.ps1  # Full validation
pwsh -NoProfile -File scripts/utils/code-quality/run-lint.ps1          # Lint only
pwsh -NoProfile -File scripts/utils/security/run-security-scan.ps1  # Security scan
```

### Performance

```powershell
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -Iterations 30
pwsh -NoProfile -File scripts/utils/metrics/benchmark-startup.ps1 -UpdateBaseline  # Update baseline
```

### Documentation

- [PROFILE_README.md](PROFILE_README.md) — Comprehensive technical guide
- [CONTRIBUTING.md](CONTRIBUTING.md) — Development and contribution guidelines
- [PROFILE_DEBUG.md](PROFILE_DEBUG.md) — Debugging and instrumentation
- [docs/README.md](docs/README.md) — API documentation (auto-generated)

## Project Structure

```text
├── Microsoft.PowerShell_profile.ps1  # Main profile loader
├── profile.d/                         # Modular fragments (00-99)
│   ├── 00-bootstrap.ps1               # Registration helpers
│   ├── 06-oh-my-posh.ps1              # Prompt framework
│   ├── 11-git.ps1                     # Git helpers
│   └── 22-containers.ps1              # Container utilities
├── scripts/                           # Validation & utilities
│   ├── checks/                        # Validation scripts
│   ├── lib/                           # Shared script modules (Common.psm1)
│   ├── utils/                         # Helper scripts (organized by category)
│   │   ├── code-quality/              # Linting, formatting, testing
│   │   ├── metrics/                   # Performance and code metrics
│   │   ├── docs/                      # Documentation generation
│   │   ├── dependencies/              # Dependency management
│   │   ├── security/                  # Security scanning
│   │   ├── release/                   # Release management
│   │   └── fragment/                  # Fragment management
│   ├── templates/                     # Script templates
│   └── examples/                      # Usage examples
└── docs/                              # Auto-generated API docs
```

## License

Open source. See individual files for licensing information.
