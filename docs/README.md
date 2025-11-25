# PowerShell Profile Documentation

Welcome to the PowerShell Profile documentation! This documentation is organized into several sections to help you find what you need.

## Documentation Structure

### 📚 [API Reference](api/)

Complete reference documentation for all functions and aliases available in the profile.

- **Functions**: [Browse all functions](api/functions/) organized by fragment
- **Aliases**: [Browse all aliases](api/aliases/) organized by fragment
- **Index**: [Full API index](api/README.md) with functions and aliases grouped by source fragment

The API documentation is automatically generated from comment-based help in the profile functions and aliases.

### 🧩 [Fragment Documentation](fragments/)

Documentation for each profile fragment, explaining what each fragment does and what functions it provides.

- **Fragment Index**: [Browse all fragments](fragments/README.md) organized by load order
- **Individual Fragments**: See detailed documentation for each fragment

Fragments are modular components of the profile, loaded in dependency-aware order (00-99). Many fragments use organized subdirectories for related modules:

- **Main Fragments** (00-99): Core fragments that load and orchestrate modules
- **Module Subdirectories**: Organized modules loaded by parent fragments
  - `cli-modules/` - Modern CLI tool integrations
  - `container-modules/` - Container helper modules
  - `conversion-modules/` - Data/document/media format conversions
  - `dev-tools-modules/` - Development tool integrations
  - `diagnostics-modules/` - Diagnostic and monitoring modules
  - `files-modules/` - File operation modules
  - `git-modules/` - Git integration modules
  - `utilities-modules/` - Utility function modules

### 📖 [Developer Guides](guides/)

Comprehensive guides for developers working on or contributing to the profile.

- **Development Guide**: [DEVELOPMENT.md](guides/DEVELOPMENT.md) - Developer guide and advanced testing
- **Codebase Improvements**: [CODEBASE_IMPROVEMENTS.md](guides/CODEBASE_IMPROVEMENTS.md) - Improvement proposals and implementation status
- **Improvements Implemented**: [IMPROVEMENTS_IMPLEMENTED.md](guides/IMPROVEMENTS_IMPLEMENTED.md) - Details of implemented improvements
- **Function Naming Exceptions**: [FUNCTION_NAMING_EXCEPTIONS.md](guides/FUNCTION_NAMING_EXCEPTIONS.md) - Exceptions to standard naming conventions
- **Security Allowlist**: [SECURITY_ALLOWLIST.md](guides/SECURITY_ALLOWLIST.md) - Security scanning allowlist

## Quick Links

- **Main Profile README**: [PROFILE_README.md](../PROFILE_README.md) - Comprehensive profile documentation
- **Architecture**: [ARCHITECTURE.md](../ARCHITECTURE.md) - Technical architecture details
- **Contributing**: [CONTRIBUTING.md](../CONTRIBUTING.md) - How to contribute
- **Agent Guidelines**: [AGENTS.md](../AGENTS.md) - Guidelines for AI coding assistants

## Documentation Generation

All documentation is automatically generated from source code:

- **API Documentation**: Run `task generate-docs` or `pwsh -NoProfile -File scripts/utils/docs/generate-docs.ps1`
- **Fragment Documentation**: Run `task generate-fragment-readmes` or `pwsh -NoProfile -File scripts/utils/docs/generate-fragment-readmes.ps1`
- **All Documentation**: Run `task all-docs` to generate both

## Statistics

- **Total Functions**: See [API index](api/README.md) for current count
- **Total Aliases**: See [API index](api/README.md) for current count
- **Total Fragments**: See [Fragment index](fragments/README.md) for current count

---

_Last updated: 2025-01-XX_

