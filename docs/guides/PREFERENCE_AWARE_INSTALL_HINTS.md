# Preference-Aware Install Hints

## Overview

The preference-aware install hint system provides intelligent, user-customizable installation recommendations for missing tools. It respects user preferences for package managers, runtimes, and system package managers across multiple languages and platforms.

## Integration Points

| Area | Location |
| ---- | -------- |
| Core API | `profile.d/bootstrap/MissingToolWarnings.ps1` — `Get-PreferenceAwareInstallHint`, `Set-PreferenceAwareInstallPreferences`, `Test-PreferenceAwareInstallPreferences` |
| Profile fragments | Language and tool fragments under `profile.d/` (for example `pip.ps1`, `pnpm.ps1`, `lang-rust.ps1`) |
| Shared utilities | `scripts/lib/utilities/Command.psm1` — `Get-ToolInstallHint`, `Resolve-InstallCommand` |
| Dependency checks | `scripts/utils/dependencies/check-missing-packages.ps1` |
| Code quality scripts | `scripts/utils/code-quality/spellcheck.ps1`, `run-markdownlint.ps1` |
| Runtime helpers | `scripts/lib/runtime/Python.psm1`, `scripts/lib/runtime/NodeJs.psm1` |
| Tests | `tests/TestSupport/ToolDetection.ps1`; integration tests in `tests/integration/bootstrap/` |

## Supported Preferences

### Language-Specific Package Managers

1. **Python** (`PS_PYTHON_PACKAGE_MANAGER`)

   - Options: `auto`, `uv`, `pip`, `conda`, `poetry`, `pipenv`, `pdm`, `hatch`, `rye`
   - Affects: Python package installation hints

2. **Node.js** (`PS_NODE_PACKAGE_MANAGER`)

   - Options: `auto`, `pnpm`, `npm`, `yarn`, `bun`
   - Affects: Node.js package installation hints

3. **Rust** (`PS_RUST_PACKAGE_MANAGER`)

   - Options: `auto`, `cargo`, `cargo-binstall`
   - Affects: Rust tool installation hints

4. **Go** (`PS_GO_PACKAGE_MANAGER`)

   - Options: `auto`, `go-install`, `go-get`
   - Affects: Go tool installation hints

5. **Java** (`PS_JAVA_BUILD_TOOL`)

   - Options: `auto`, `maven`, `gradle`, `sbt`
   - Affects: Java build tool installation hints

6. **Ruby** (`PS_RUBY_PACKAGE_MANAGER`)

   - Options: `auto`, `gem`, `bundler`
   - Affects: Ruby gem installation hints

7. **PHP** (`PS_PHP_PACKAGE_MANAGER`)

   - Options: `auto`, `composer`, `pecl`, `pear`
   - Affects: PHP package installation hints

8. **.NET** (`PS_DOTNET_PACKAGE_MANAGER`)

   - Options: `auto`, `dotnet`, `nuget`
   - Affects: .NET package installation hints

9. **Dart** (`PS_DART_PACKAGE_MANAGER`)

   - Options: `auto`, `flutter`, `pub`
   - Affects: Dart/Flutter package installation hints

10. **Elixir** (`PS_ELIXIR_PACKAGE_MANAGER`)
    - Options: `auto`, `mix`, `hex`
    - Affects: Elixir package installation hints

### Runtime Preferences

1. **Python Runtime** (`PS_PYTHON_RUNTIME`)
   - Options: `auto`, `python`, `python3`, `py`
   - Affects: Python executable detection and installation hints

### System Package Manager Preference

1. **System Package Manager** (`PS_SYSTEM_PACKAGE_MANAGER`)
   - **Windows**: `auto`, `scoop`, `winget`, `chocolatey`
   - **Linux**: `auto`, `apt`, `yum`, `dnf`, `pacman`, `scoop`
   - **macOS**: `auto`, `homebrew`, `scoop`
   - Affects: Generic tool installation hints when language-specific preferences don't apply

## Implementation Details

### How It Works

1. **Preference Detection**: Reads environment variables from `.env` or `.env.local`
2. **Tool Type Auto-Detection**: Automatically identifies tool type from name patterns
3. **Availability Checking**: Verifies preferred tools are actually available
4. **Fallback Chains**: Falls back to alternatives if preferred tool isn't available
5. **Platform Awareness**: Detects platform and suggests appropriate installers

### Fallback Behavior

The system implements intelligent fallback chains with prioritized alternatives:

- **Language Preferences**: Falls back to alternative package managers if preferred isn't available
  - Shows multiple options in priority order: `preferred (or: fallback1, or: fallback2)`
  - Example: If `uv` is preferred but unavailable, suggests `uv tool install tool (or: pip install tool, or: poetry add tool)`
- **System Package Manager**: Falls back to detected package managers if preference isn't available
  - Windows: `scoop install tool (or: winget install tool, or: choco install tool -y)`
  - Linux: `sudo apt install tool (or: sudo dnf install tool, or: sudo yum install tool)`
  - macOS: `brew install tool (or: scoop install tool)`
- **Platform Detection**: Suggests platform-appropriate installers with fallback chains
- **Availability Checking**: Only shows fallback options that are actually available on the system

### Example Usage

```powershell
# Set preferences in .env or .env.local
PS_PYTHON_PACKAGE_MANAGER=uv
PS_NODE_PACKAGE_MANAGER=pnpm
PS_RUST_PACKAGE_MANAGER=cargo-binstall
PS_SYSTEM_PACKAGE_MANAGER=scoop

# When tools are missing, hints respect preferences with fallbacks:
# Missing pipenv → "Install with: uv tool install pipenv (or: pip install pipenv, or: poetry add pipenv)"
# Missing typescript → "Install with: pnpm add -g typescript (or: npm install -g typescript, or: yarn global add typescript)"
# Missing cargo-watch → "Install with: cargo-binstall cargo-watch (or: cargo install cargo-watch)"
# Missing generic-tool → "Install with: scoop install generic-tool (or: winget install generic-tool, or: choco install generic-tool -y)"
```

### Fallback Chain Examples

When the preferred package manager is unavailable, the system automatically shows available alternatives:

**Windows Example:**

- Preference: `PS_SYSTEM_PACKAGE_MANAGER=scoop`
- If Scoop unavailable: `"Install with: winget install tool (or: choco install tool -y)"`
- If all unavailable: Shows all options: `"Install with: scoop install tool (or: winget install tool, or: choco install tool -y)"`

**Python Example:**

- Preference: `PS_PYTHON_PACKAGE_MANAGER=uv`
- If uv unavailable: `"Install with: pip install tool (or: poetry add tool)"`
- If uv available: `"Install with: uv tool install tool (or: pip install tool, or: poetry add tool)"`

**Node.js Example:**

- Preference: `PS_NODE_PACKAGE_MANAGER=pnpm`
- If pnpm unavailable: `"Install with: npm install -g tool (or: yarn global add tool)"`
- If pnpm available: `"Install with: pnpm add -g tool (or: npm install -g tool, or: yarn global add tool)"`

## Considerations and Best Practices

### Platform compatibility

Platform detection drives system package manager suggestions (Windows/Linux/macOS). Some tools still need tool-specific install methods (curl scripts, direct downloads)—extend `Get-ToolSpecificInstallMethod` when adding those.

### Performance

Uses `Test-CachedCommand` for command detection. Preference resolution runs per hint request; avoid calling `Get-PreferenceAwareInstallHint` in tight loops.

### Error handling and fallbacks

Preference helpers use try/catch with graceful degradation: invalid values are treated as `auto`, missing helpers fall back to hardcoded install commands, and unavailable package managers trigger the next option in the fallback chain (up to three alternatives).

### Consistency

Language fragments share the same `Get-PreferenceAwareInstallHint` pattern. Some older call sites still use `Get-ToolInstallHint`, which delegates to the preference-aware path when available.

### Testing

- Unit: `tests/unit/profile-preference-aware-install-hints.tests.ps1`
- Integration: `tests/integration/bootstrap/preference-aware-install-hints-*.tests.ps1`

### Cross-platform notes

Platform detection drives system package manager suggestions. Runtime names may differ by platform (`python3` vs `python`). Tools with non-package-manager installs (curl scripts, direct downloads) can be added via `Get-ToolSpecificInstallMethod`.

## Available Functions

### Core Functions

1. **`Get-PreferenceAwareInstallHint`**

   - Main function for generating preference-aware install hints
   - Auto-detects tool type, respects preferences, provides fallback chains
   - Parameters: `-ToolName`, `-ToolType`, `-DefaultInstallCommand`

2. **`Get-ToolSpecificInstallMethod`**

   - Retrieves tool-specific installation methods from registry
   - Checks availability and respects preferences
   - Parameters: `-ToolName`, `-Platform`, `-PreferredMethod`

3. **`Get-ToolInstallMethodRegistry`**

   - Returns registry of tool-specific installation methods
   - Organized by tool name, platform, and package manager

4. **`Get-SystemPackageManagerFallbackChain`**

   - Generates prioritized fallback chain for system package managers
   - Platform-aware with availability checking
   - Parameters: `-ToolName`, `-Platform`, `-PreferredManager`

5. **`Get-InstallMethodFallbackChain`**

   - Formats fallback chain with preferred method and alternatives
   - Parameters: `-PreferredMethod`, `-FallbackMethods`, `-MaxFallbacks`

6. **`Set-PreferenceAwareInstallPreferences`**

   - Interactive preference setup wizard
   - Detects available tools and guides user through setup
   - Parameters: `-PreferenceType`, `-NonInteractive`

7. **`Test-PreferenceAwareInstallPreferences`**

   - Validates preference values and availability
   - Returns structured results with errors and warnings
   - Parameters: `-PreferenceType`

8. **`Test-CommandAvailable`**
   - Helper function to check if a command is available
   - Maps package manager names to actual commands
   - Parameters: `-CommandName`

## Possible Future Enhancements

- Expand the tool-specific install method registry (`Get-ToolSpecificInstallMethod`) beyond current entries (`pnpm`, `uv`, `poetry`, `cargo-binstall`)
- Version preferences (for example prefer Python 3.12 over 3.11)
- Project-level preferences (for example `.preferences.json` in a repo root)
- Preference profiles or export/import for syncing across machines

## Usage Examples

### Setting Preferences

```bash
# .env or .env.local
PS_PYTHON_PACKAGE_MANAGER=uv
PS_NODE_PACKAGE_MANAGER=pnpm
PS_RUST_PACKAGE_MANAGER=cargo-binstall
PS_SYSTEM_PACKAGE_MANAGER=scoop
PS_PYTHON_RUNTIME=python3
```

### Using in Code

```powershell
# Automatic (recommended)
$hint = Get-PreferenceAwareInstallHint -ToolName 'pipenv'
Write-MissingToolWarning -Tool 'pipenv' -InstallHint $hint

# Explicit tool type
$hint = Get-PreferenceAwareInstallHint -ToolName 'typescript' -ToolType 'node-package'
Write-MissingToolWarning -Tool 'typescript' -InstallHint $hint

# With fallback default
$hint = Get-PreferenceAwareInstallHint -ToolName 'custom-tool' -DefaultInstallCommand 'scoop install custom-tool'
Write-MissingToolWarning -Tool 'custom-tool' -InstallHint $hint
```

### Interactive Preference Setup

```powershell
# Interactive setup for all preferences
Set-PreferenceAwareInstallPreferences

# Interactive setup for specific preference type
Set-PreferenceAwareInstallPreferences -PreferenceType 'python-package'

# Non-interactive mode (uses current values)
Set-PreferenceAwareInstallPreferences -NonInteractive
```

### Preference Validation

```powershell
# Validate all preferences
$validation = Test-PreferenceAwareInstallPreferences
if (-not $validation.Valid) {
    Write-Warning "Invalid preferences: $($validation.Errors -join ', ')"
}

# Validate specific preference type
$validation = Test-PreferenceAwareInstallPreferences -PreferenceType 'python-package'
if ($validation.Warnings.Count -gt 0) {
    foreach ($warning in $validation.Warnings) {
        Write-Warning $warning
    }
}
```

### Tool-Specific Installation Methods

```powershell
# Get tool-specific installation method
$method = Get-ToolSpecificInstallMethod -ToolName 'pnpm'
if ($method) {
    Write-Output "Install with: $method"
}

# Get system package manager fallback chain
$fallbackInfo = Get-SystemPackageManagerFallbackChain -ToolName 'test-tool'
Write-Output "Fallback chain: $($fallbackInfo.FallbackChain)"
```

## Related Documentation

- [AGENTS.md](../../AGENTS.md) - AI assistant guidelines
- [ARCHITECTURE.md](../../ARCHITECTURE.md) - Technical architecture
- [PROFILE_README.md](../../PROFILE_README.md) - Profile documentation
- `.env.example` - Environment variable examples
