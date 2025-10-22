# PowerShell Profile

[![Validate PowerShell Profile](https://github.com/bolens/ps-profile/actions/workflows/validate-profile.yml/badge.svg)](https://github.com/bolens/ps-profile/actions/workflows/validate-profile.yml)
[![Commit message check](https://github.com/bolens/ps-profile/actions/workflows/commit-message-check.yml/badge.svg)](https://github.com/bolens/ps-profile/actions/workflows/commit-message-check.yml)

A modular, performance-optimized PowerShell profile for interactive shells. Features lazy loading, container helpers, prompt frameworks (oh-my-posh/Starship), and comprehensive validation tooling.

## Quick Start

1. Clone this repository to your PowerShell profile location:
   ```powershell
   git clone https://github.com/bolens/ps-profile.git $HOME\Documents\PowerShell
   ```

2. Reload your profile:
   ```powershell
   . $PROFILE
   ```

## Features

- **Modular Design**: Profile functionality split into small, maintainable fragments in `profile.d/`
- **Performance Optimized**: Lazy loading and deferred initialization keep startup fast
- **Container Support**: Docker/Podman helpers with auto-detection
- **Prompt Frameworks**: Support for oh-my-posh and Starship with lazy initialization
- **Comprehensive Validation**: Linting, security scanning, idempotency testing, and benchmarking
- **Git Integration**: Pre-commit hooks and CI workflows

## Structure

- `Microsoft.PowerShell_profile.ps1` — Main profile loader
- `profile.d/` — Modular fragments loaded in lexical order
  - `00-bootstrap.ps1` — Helper functions for safe registration
  - `01-paths.ps1` — PATH normalization
  - `06-oh-my-posh.ps1` / `20-starship.ps1` — Prompt initialization
  - `10-git.ps1` — Git helpers
  - `20-containers.ps1` — Container management utilities
- `scripts/` — Utility scripts for validation, formatting, and maintenance

## Validation & Testing

Run comprehensive checks before committing:

```powershell
# Full validation (lint + security + idempotency)
pwsh -NoProfile -File scripts/checks/validate-profile.ps1

# Individual checks
pwsh -NoProfile -File scripts/utils/run-lint.ps1          # PSScriptAnalyzer
pwsh -NoProfile -File scripts/utils/run-security-scan.ps1 # Security analysis
pwsh -NoProfile -File scripts/checks/check-idempotency.ps1 # Idempotency test
```

## Performance Benchmarking

Measure startup performance:

```powershell
pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -Iterations 30
```

## Contributing

See [CONTRIBUTING.md](CONTRIBUTING.md) for development setup, validation scripts, and contribution guidelines.

## Documentation

- [Detailed Profile Documentation](PROFILE_README.md) — Comprehensive guide
- [Debug Guide](PROFILE_DEBUG.md) — Debugging and instrumentation
- [PowerShell Config](powershell.config.README.md) — Configuration details

## License

This project is open source. See individual files for licensing information.
