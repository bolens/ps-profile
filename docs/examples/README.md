# Documentation Examples

This directory contains practical examples demonstrating how to use various features and patterns in the PowerShell profile.

## Available Examples

### [Module Loading](MODULE_LOADING.md)

Examples for using the standardized module loading system (`Import-FragmentModule` and `Import-FragmentModules`):

- Loading single and multiple modules
- Dependency management
- Retry logic and error handling
- Performance optimization with caching
- Migration from old patterns

**When to use**: When loading submodules in fragments or creating new fragments that depend on other modules.

### [Tool Wrapper](TOOL_WRAPPER.md)

Examples for using `Register-ToolWrapper` and `Get-ToolInstallHint` to create standardized wrapper functions with centralized install hints:

- Simple tool wrappers
- Custom warning messages
- Multiple tool registration
- Integration with module loading
- Migration from manual wrappers

**When to use**: When creating wrappers for external tools (CLI applications, utilities, etc.).

### [Fragment Creation](FRAGMENT_CREATION.md)

Complete guide for creating new fragments following modern patterns:

- Fragment structure and templates
- Dependency declarations
- Tier specifications
- Error handling patterns
- Best practices and migration checklist

**When to use**: When creating new fragments or migrating existing numbered fragments to named fragments.

### [Command Detection](COMMAND_DETECTION.md)

Examples for using `Test-CachedCommand` for fast, cached command detection:

- Basic command detection
- Conditional function registration
- Feature detection
- Performance optimization
- Migration from deprecated patterns

**When to use**: When checking for tool availability before using commands or loading modules.

### [Locale Usage](LOCALE_USAGE.md)

Examples for using the `Locale.psm1` module for locale-aware output formatting:

- Locale detection
- Date, number, and currency formatting
- Localized messages
- Integration with utility scripts

**When to use**: When creating scripts that need locale-aware formatting or UK/US English spelling differences.

### [Error Handling](ERROR_HANDLING.md)

Examples for standardized error handling patterns:

- Fragment error handling with `Write-ProfileError`
- Utility script error handling with `Exit-WithCode`
- Missing tool warnings with `Write-MissingToolWarning`
- Error handling best practices

**When to use**: When writing fragments, utility scripts, or handling errors in any PowerShell code.

### [Utility Scripts](UTILITY_SCRIPTS.md)

Complete guide for writing utility scripts in `scripts/utils/`:

- Module import patterns
- Path resolution with `Get-RepoRoot`
- Error handling with `Exit-WithCode`
- Logging with `Write-ScriptMessage`
- Non-interactive execution

**When to use**: When creating new utility scripts or validation scripts in `scripts/utils/` or `scripts/checks/`.

### [Testing Patterns](TESTING_PATTERNS.md)

Guide for writing tests following project standards:

- Test structure with TestSupport.ps1
- Path resolution in tests
- Mocking external dependencies
- Test data setup and cleanup
- Best practices for unit and integration tests

**When to use**: When writing Pester tests for functions, modules, or fragments.

## Quick Reference

### Common Patterns

**Module Loading:**

```powershell
Import-FragmentModule `
    -FragmentRoot $PSScriptRoot `
    -ModulePath @('modules', 'example.ps1') `
    -Context "Fragment: example"
```

**Tool Wrapper:**

```powershell
Register-ToolWrapper `
    -FunctionName 'bat' `
    -CommandName 'bat' `
    -InstallHint 'Install with: scoop install bat'
```

**Command Detection:**

```powershell
if (Test-CachedCommand 'docker') {
    docker ps
}
```

**Function Registration:**

```powershell
Set-AgentModeFunction -Name 'MyFunction' -Body ${function:MyFunction}
Set-AgentModeAlias -Name 'mf' -Target 'MyFunction'
```

**Error Handling:**

```powershell
# Fragments
Write-ProfileError -ErrorRecord $_ -Context "Fragment: example" -Category 'Fragment'

# Utility scripts
Exit-WithCode -ExitCode $EXIT_VALIDATION_FAILURE -Message "Validation failed"

# Missing tools
Write-MissingToolWarning -Tool 'docker' -InstallHint 'Install with: scoop install docker'
```

## Related Documentation

- [AGENTS.md](../../AGENTS.md) - Quick start guide for AI assistants
- [Module Expansion Plan](../guides/MODULE_EXPANSION_PLAN.md) - Comprehensive module implementation guide
- [Implementation Roadmap](../guides/IMPLEMENTATION_ROADMAP.md) - Implementation phases and timeline
- [Module Loading Standard](../guides/MODULE_LOADING_STANDARD.md) - Detailed module loading specification

## Contributing

When adding new examples:

1. Follow the format of existing examples
2. Include real-world use cases
3. Show both basic and advanced usage
4. Include migration examples when applicable
5. Add cross-references to related examples
6. Update this README with a brief description
