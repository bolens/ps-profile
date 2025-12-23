# Preference Awareness Implementation Summary

## Overview

This document summarizes all the places where preference-aware install hints and package manager preferences have been implemented throughout the PowerShell profile project.

## Core Implementation

### Primary Location

- **`profile.d/bootstrap/MissingToolWarnings.ps1`**
  - `Get-PreferenceAwareInstallHint` - Main function for generating preference-aware hints
  - `Get-ToolSpecificInstallMethod` - Tool-specific installation method registry
  - `Get-ToolInstallMethodRegistry` - Registry of tool-specific methods
  - `Get-SystemPackageManagerFallbackChain` - System package manager fallback chains
  - `Get-InstallMethodFallbackChain` - Fallback chain formatting
  - `Set-PreferenceAwareInstallPreferences` - Interactive preference setup
  - `Test-PreferenceAwareInstallPreferences` - Preference validation
  - `Test-CommandAvailable` - Command availability checking

## Profile Fragments

All language-specific fragments now use preference-aware install hints:

### Python Package Managers

- `profile.d/pipenv.ps1`
- `profile.d/poetry.ps1`
- `profile.d/hatch.ps1`
- `profile.d/pdm.ps1`
- `profile.d/rye.ps1`
- `profile.d/uv.ps1`
- `profile.d/pip.ps1`
- `profile.d/conda.ps1`

### Node.js Package Managers

- `profile.d/npm.ps1`
- `profile.d/pnpm.ps1`
- `profile.d/yarn.ps1`
- `profile.d/bun.ps1`

### Language Runtimes

- `profile.d/lang-rust.ps1`
- `profile.d/lang-go.ps1`
- `profile.d/lang-java.ps1`
- `profile.d/gem.ps1` (Ruby)
- `profile.d/php.ps1`
- `profile.d/dotnet.ps1`
- `profile.d/dart.ps1`
- `profile.d/mix.ps1` (Elixir)

### Other Tools

- `profile.d/conan.ps1`
- `profile.d/cocoapods.ps1`
- `profile.d/angular.ps1`
- `profile.d/deno.ps1`

## Test Support

### Test Tool Detection

- **`tests/TestSupport/ToolDetection.ps1`**
  - `Get-ToolRecommendations` - Now uses `Get-PreferenceAwareInstallHint` for all tool recommendations
  - Automatically detects tool types and uses appropriate preferences
  - Falls back to defaults if preference-aware hints unavailable

## Utility Scripts

### Command Utilities

- **`scripts/lib/utilities/Command.psm1`**
  - `Get-ToolInstallHint` - Now uses `Get-PreferenceAwareInstallHint` as primary method
  - Falls back to requirements-based lookup if preference-aware hint unavailable
  - `Resolve-InstallCommand` - Already had preference support for Node/Python, enhanced for system tools

### Dependency Management

- **`scripts/utils/dependencies/check-missing-packages.ps1`**
  - Python package checks now use preference-aware hints
  - System package checks use preference-aware fallback chains
  - Shows multiple installation options when available

### Code Quality Tools

- **`scripts/utils/code-quality/spellcheck.ps1`**

  - Uses preference-aware hints for `cspell` installation suggestions
  - Respects `PS_NODE_PACKAGE_MANAGER` preference

- **`scripts/utils/code-quality/run-markdownlint.ps1`**
  - Uses `Get-NodePackageInstallCommand` for installing markdownlint-cli
  - Respects `PS_NODE_PACKAGE_MANAGER` preference

### Documentation Generation

- **`scripts/utils/docs/generate-changelog.ps1`**
  - Uses preference-aware hints for `git-cliff` installation suggestions
  - Shows fallback options when preferred method unavailable

## Runtime Modules

### Python Runtime

- **`scripts/lib/runtime/Python.psm1`**
  - `Get-PythonPackageManagerPreference` - Already implements preference support
  - `Get-PythonPackageInstallCommand` - Uses preferences
  - Could be enhanced to use fallback chains (future enhancement)

### Node.js Runtime

- **`scripts/lib/runtime/NodeJs.psm1`**
  - `Get-NodePackageManagerPreference` - Already implements preference support
  - `Get-NodePackageInstallCommand` - Uses preferences
  - Could be enhanced to use fallback chains (future enhancement)

## Benefits

### User Experience

1. **Consistent Preferences**: All tools respect user preferences across the entire project
2. **Fallback Support**: Multiple installation options shown when preferred method unavailable
3. **Platform Awareness**: Platform-specific suggestions with appropriate fallbacks
4. **Interactive Setup**: Easy preference configuration via `Set-PreferenceAwareInstallPreferences`

### Developer Experience

1. **Centralized Logic**: Single source of truth for install hint generation
2. **Easy Integration**: Simple function call to get preference-aware hints
3. **Graceful Degradation**: Falls back to defaults if preference system unavailable
4. **Comprehensive Testing**: Full test coverage for all preference logic

## Usage Patterns

### In Profile Fragments

```powershell
else {
    $installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
        Get-PreferenceAwareInstallHint -ToolName 'tool-name' -ToolType 'language-package' -DefaultInstallCommand 'fallback command'
    }
    else {
        'Default hardcoded fallback command'
    }
    Write-MissingToolWarning -Tool 'tool-name' -InstallHint $installHint
}
```

### In Utility Scripts

```powershell
# Get preference-aware install hint
$installHint = if (Get-Command Get-PreferenceAwareInstallHint -ErrorAction SilentlyContinue) {
    try {
        $hint = Get-PreferenceAwareInstallHint -ToolName 'tool' -ToolType 'generic' -DefaultInstallCommand 'scoop install tool'
        if ($hint -match '^Install with:\s*(.+)$') {
            $matches[1]
        }
        else {
            'scoop install tool'
        }
    }
    catch {
        'scoop install tool'
    }
}
else {
    'scoop install tool'
}
```

### In Test Support

```powershell
# Automatically uses preference-aware hints
$tools = Get-ToolRecommendations
# Each tool's InstallCommand is now preference-aware
```

## Future Enhancement Opportunities

### Additional Integration Points

1. **Fragment Loading**: Could validate preferences during fragment load
2. **Setup Scripts**: Installation/setup scripts could use preferences
3. **CI/CD Workflows**: GitHub Actions could respect preferences
4. **Documentation Generation**: Auto-generate preference-aware installation docs

### Enhanced Features

1. **Preference Caching**: Cache preference lookups for performance
2. **Preference Profiles**: Named preference profiles (dev, prod, etc.)
3. **Project-Level Preferences**: `.preferences.json` in project root
4. **Preference Sync**: Sync preferences across machines

## Testing

All preference awareness features are covered by comprehensive tests:

- **Unit Tests**: `tests/unit/preference-aware-install-hints.tests.ps1`
- **Integration Tests**: `tests/integration/bootstrap/preference-aware-install-hints-fallback.tests.ps1`
- **Platform Tests**: `tests/integration/bootstrap/preference-aware-install-hints-platform.tests.ps1`

## Related Documentation

- [PREFERENCE_AWARE_INSTALL_HINTS.md](PREFERENCE_AWARE_INSTALL_HINTS.md) - Complete user guide
- [AGENTS.md](../AGENTS.md) - AI assistant guidelines
- `.env.example` - Environment variable examples
