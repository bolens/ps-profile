# PowerShell Profile Documentation

Welcome to the PowerShell Profile documentation! This documentation is organized into several sections to help you find what you need.

> **Note:** This profile is under active development and may be unstable. See [README.md](../README.md) for the full warning.

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

Fragments are modular components of the profile, loaded in dependency-aware order (tier-based: core, essential, standard, optional). Many fragments use organized subdirectories for related modules:

- **Main Fragments**: 130+ top-level scripts in `profile.d/` (e.g. `bootstrap.ps1`, `git.ps1`, `files.ps1`) that load and orchestrate modules
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

- **Guide Index**: [Browse all guides](guides/README.md) - Full categorized guide index
- **Testing Guide**: [TESTING.md](guides/TESTING.md) - **Primary** testing reference (structure, runner flags, batch scripts, coverage)
- **Development Guide**: [DEVELOPMENT.md](guides/DEVELOPMENT.md) - Setup, workflow, and advanced runner features
- **Testing Patterns**: [TESTING_PATTERNS.md](examples/TESTING_PATTERNS.md) - Code examples for writing tests
- **Test Stub Guide**: [TEST_VERIFICATION_MOCKING_GUIDE.md](guides/TEST_VERIFICATION_MOCKING_GUIDE.md) - TestSupport stubs and isolation
- **Coverage Verification**: [VERIFY_COVERAGE.md](guides/VERIFY_COVERAGE.md) - Per-module `analyze-coverage.ps1` workflows
- **Quick Start**: [DEVELOPMENT_QUICK_START.md](guides/DEVELOPMENT_QUICK_START.md) - Fast profile loading and common dev commands
- **Error Handling Standard**: [ERROR_HANDLING_STANDARD.md](guides/ERROR_HANDLING_STANDARD.md) - Error handling, logging, and color coding standards
- **Fragment Command Access**: [FRAGMENT_COMMAND_ACCESS.md](guides/FRAGMENT_COMMAND_ACCESS.md) - How to access fragment-defined commands
- **Type Safety Guide**: [TYPE_SAFETY.md](guides/TYPE_SAFETY.md) - Enums, classes, validation, and strict mode
- **Function Naming Exceptions**: [FUNCTION_NAMING_EXCEPTIONS.md](guides/FUNCTION_NAMING_EXCEPTIONS.md) - Exceptions to standard naming conventions
- **Security Allowlist**: [SECURITY_ALLOWLIST.md](guides/SECURITY_ALLOWLIST.md) - Security scanning allowlist
- **Tool Requirements**: [TOOL_REQUIREMENTS.md](guides/TOOL_REQUIREMENTS.md) - Test/conversion dependencies ([requirements.txt](../requirements.txt), [scoop.txt](../requirements/scoop.txt), [linux.txt](../requirements/linux.txt))
- **Fragment Cache**: [FRAGMENT_CACHE_USAGE.md](guides/FRAGMENT_CACHE_USAGE.md) - SQLite fragment cache and utility scripts
- **Fragment Loading**: [FRAGMENT_LOADING_OPTIMIZATION.md](guides/FRAGMENT_LOADING_OPTIMIZATION.md) - Lazy loading and command pre-registration
- **Module Loading**: [MODULE_LOADING_STANDARD.md](guides/MODULE_LOADING_STANDARD.md) - `Import-FragmentModule` patterns
- **Preference-Aware Hints**: [PREFERENCE_AWARE_INSTALL_HINTS.md](guides/PREFERENCE_AWARE_INSTALL_HINTS.md) - Install hint preferences

See the [full guide index](guides/README.md) for performance, SQLite, and advanced topics.

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

After editing guides or the source files they describe, refresh drift bindings:

```powershell
task drift-link    # updates drift.lock for tests and guides
task drift-check   # included in quality-check
```

## Statistics

- **Total Functions**: See [API index](api/README.md) for current count
- **Total Aliases**: See [API index](api/README.md) for current count
- **Total Fragments**: See [Fragment index](fragments/README.md) for current count


