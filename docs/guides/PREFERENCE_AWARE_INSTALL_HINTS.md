# Preference-Aware Install Hints

## Overview

The preference-aware install hint system provides intelligent, user-customizable installation recommendations for missing tools. It respects user preferences for package managers, runtimes, and system package managers across multiple languages and platforms.

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

### 1. **Platform Compatibility**

- ✅ **Implemented**: Platform detection (Windows/Linux/macOS)
- ✅ **Implemented**: Platform-specific system package manager suggestions
- ⚠️ **Consider**: Some tools may have platform-specific installation methods (e.g., curl scripts)

### 2. **Performance**

- ✅ **Current**: Uses `Test-CachedCommand` for efficient command detection
- ✅ **Current**: Preference functions check availability once
- 💡 **Future Enhancement**: Could cache preference lookups to avoid repeated checks

### 3. **Error Handling**

- ✅ **Current**: Try-catch blocks around preference function calls
- ✅ **Current**: Graceful fallback to defaults if preferences fail
- ✅ **Current**: Fallback to hardcoded defaults if helper function unavailable

### 4. **Consistency**

- ✅ **Current**: All language fragments use same pattern
- ✅ **Current**: Consistent fallback behavior across languages
- ⚠️ **Note**: Some fragments may still use `Get-ToolInstallHint` for backward compatibility

### 5. **Tool Availability Verification**

- ✅ **Current**: Preference functions verify tool availability before suggesting
- ✅ **Current**: Falls back to alternatives if preferred tool unavailable
- ✅ **Implemented**: Provides multiple prioritized suggestions when multiple managers available
- ✅ **Implemented**: Fallback chains show up to 3 alternatives in priority order

### 6. **Documentation**

- ✅ **Current**: `.env.example` documents all preferences
- ✅ **Current**: Function help includes examples
- 💡 **Enhancement**: Could add user guide with examples

### 7. **Testing** ✅ **Implemented**

- ✅ **Implemented**: Unit tests for preference detection logic
- ✅ **Implemented**: Integration tests for fallback chains
- ✅ **Implemented**: Cross-platform tests for platform-specific suggestions
- ✅ **Implemented**: Edge case tests (missing tools, invalid preferences, etc.)
- See `tests/unit/preference-aware-install-hints.tests.ps1` and `tests/integration/bootstrap/preference-aware-install-hints-*.tests.ps1`

### 8. **Edge Cases**

- ✅ **Handled**: Missing preference functions (falls back gracefully)
- ✅ **Handled**: Invalid preference values (treats as 'auto')
- ✅ **Handled**: No available package managers (suggests generic install)
- 💡 **Consider**: Tools with multiple installation methods (e.g., deno has curl script, scoop, brew)

### 9. **User Experience**

- ✅ **Current**: Preferences are optional (defaults work without configuration)
- ✅ **Current**: Auto-detection reduces need to specify tool types
- ✅ **Implemented**: Interactive preference setup via `Set-PreferenceAwareInstallPreferences`
- ✅ **Implemented**: Preference validation via `Test-PreferenceAwareInstallPreferences`

### 10. **Cross-Platform Considerations**

- ✅ **Current**: Platform detection works on Windows, Linux, macOS
- ✅ **Current**: Platform-specific install commands
- ⚠️ **Note**: Some tools may require different commands per platform (e.g., `python3` vs `python`)

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

## Future Enhancements

### Potential Improvements

1. **Interactive Preference Setup** ✅ **Implemented**

   - Command to detect available tools and set preferences interactively
   - Function: `Set-PreferenceAwareInstallPreferences`
   - Supports interactive and non-interactive modes

2. **Preference Validation** ✅ **Implemented**

   - Validate preference values and check availability
   - Function: `Test-PreferenceAwareInstallPreferences`
   - Warns about invalid or unavailable preferences

3. **Multiple Suggestions** ✅ **Implemented**

   - When multiple package managers available, suggest all options in priority order
   - Example: "Install with: scoop install tool (or: winget install tool, or: choco install tool -y)"
   - Automatically detects available package managers and shows them as fallbacks

4. **Tool-Specific Installation Methods** ✅ **Partially Implemented**

   - Registry system for tool-specific installation methods
   - Functions: `Get-ToolInstallMethodRegistry`, `Get-ToolSpecificInstallMethod`
   - Currently includes: `pnpm`, `uv`, `poetry`, `cargo-binstall`
   - 💡 **Enhancement**: Expand registry with more tools and special installation methods (curl scripts, direct downloads)

5. **Version Preferences**

   - Support version preferences (e.g., prefer Python 3.11 over 3.10)
   - Currently only supports runtime name preference

6. **Project-Level Preferences**

   - Support project-specific preferences (e.g., `.preferences.json` in project root)
   - Override user-level preferences for specific projects

7. **Preference Inheritance**

   - Allow preferences to inherit from parent directories
   - Useful for monorepos with different tool preferences per project

8. **Preference Export/Import**
   - Export preferences to share across machines
   - Import preferences from other developers

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

- [AGENTS.md](../AGENTS.md) - AI assistant guidelines
- [ARCHITECTURE.md](../ARCHITECTURE.md) - Technical architecture
- [PROFILE_README.md](../PROFILE_README.md) - Profile documentation
- `.env.example` - Environment variable examples
