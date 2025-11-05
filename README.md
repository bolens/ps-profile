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

### Validation

```powershell
pwsh -NoProfile -File scripts/checks/validate-profile.ps1  # Full validation
pwsh -NoProfile -File scripts/utils/run-lint.ps1          # Lint only
pwsh -NoProfile -File scripts/utils/run-security-scan.ps1  # Security scan
```

### Performance

```powershell
pwsh -NoProfile -File scripts/utils/benchmark-startup.ps1 -Iterations 30
```

### Documentation

- [PROFILE_README.md](PROFILE_README.md) — Comprehensive technical guide
- [CONTRIBUTING.md](CONTRIBUTING.md) — Development and contribution guidelines
- [PROFILE_DEBUG.md](PROFILE_DEBUG.md) — Debugging and instrumentation
- [docs/README.md](docs/README.md) — API documentation (auto-generated)

## Project Structure

```
├── Microsoft.PowerShell_profile.ps1  # Main profile loader
├── profile.d/                         # Modular fragments (00-99)
│   ├── 00-bootstrap.ps1               # Registration helpers
│   ├── 06-oh-my-posh.ps1              # Prompt framework
│   ├── 11-git.ps1                     # Git helpers
│   └── 22-containers.ps1              # Container utilities
├── scripts/                           # Validation & utilities
│   ├── checks/                        # Validation scripts
│   └── utils/                         # Helper scripts
└── docs/                              # Auto-generated API docs
```

## License

Open source. See individual files for licensing information.
