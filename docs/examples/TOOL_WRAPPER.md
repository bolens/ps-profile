# Using Standardized Tool Wrappers

This guide demonstrates how to use the `Register-ToolWrapper` function to create standardized wrapper functions for external tools with consistent error handling and command detection.

## Overview

The `Register-ToolWrapper` function provides:

- **Cached command detection** - Uses `Test-CachedCommand` for performance
- **Standardized error handling** - Consistent warnings when tools are missing
- **Install hints** - Helpful installation instructions
- **Idempotent registration** - Uses `Set-AgentModeFunction` internally
- **Custom warning messages** - Optional custom messages for missing tools

## Basic Usage

### Simple Tool Wrapper

```powershell
# Register a wrapper for a tool (function name matches command name)
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install with: scoop install bat'
```

### Tool Wrapper with Custom Warning

```powershell
# Register with a custom warning message
Register-ToolWrapper `
    -FunctionName 'http' `
    -CommandName 'http' `
    -WarningMessage 'httpie (http) not found' `
    -InstallHint 'Install with: scoop install httpie'
```

### Multiple Tool Wrappers

```powershell
# Register multiple tools at once
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install with: scoop install bat'
Register-ToolWrapper -FunctionName 'fd' -CommandName 'fd' -InstallHint 'Install with: scoop install fd'
Register-ToolWrapper -FunctionName 'zoxide' -CommandName 'zoxide' -InstallHint 'Install with: scoop install zoxide'
Register-ToolWrapper -FunctionName 'delta' -CommandName 'delta' -InstallHint 'Install with: scoop install delta'
Register-ToolWrapper -FunctionName 'tldr' -CommandName 'tldr' -InstallHint 'Install with: scoop install tldr'
```

## Real-World Examples

### Example 1: Modern CLI Tools Module

```powershell
# ===============================================
# modern-cli.ps1
# Modern CLI tools helper functions
# ===============================================

# bat - cat clone with syntax highlighting and Git integration
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install with: scoop install bat'

# fd - find files and directories
Register-ToolWrapper -FunctionName 'fd' -CommandName 'fd' -InstallHint 'Install with: scoop install fd'

# http - command-line HTTP client
Register-ToolWrapper `
    -FunctionName 'http' `
    -CommandName 'http' `
    -WarningMessage 'httpie (http) not found' `
    -InstallHint 'Install with: scoop install httpie'

# zoxide - smarter cd command
Register-ToolWrapper -FunctionName 'zoxide' -CommandName 'zoxide' -InstallHint 'Install with: scoop install zoxide'

# delta - syntax-highlighting pager for git
Register-ToolWrapper -FunctionName 'delta' -CommandName 'delta' -InstallHint 'Install with: scoop install delta'

# tldr - simplified man pages
Register-ToolWrapper -FunctionName 'tldr' -CommandName 'tldr' -InstallHint 'Install with: scoop install tldr'

# procs - modern replacement for ps
Register-ToolWrapper -FunctionName 'procs' -CommandName 'procs' -InstallHint 'Install with: scoop install procs'

# dust - more intuitive du command
Register-ToolWrapper -FunctionName 'dust' -CommandName 'dust' -InstallHint 'Install with: scoop install dust'
```

### Example 2: Security Tools Module

```powershell
# ===============================================
# security-tools.ps1
# Security scanning and analysis tools
# ===============================================
# Dependencies: bootstrap, env
# Tier: standard

# gitleaks - Git secrets scanner
Register-ToolWrapper `
    -FunctionName 'Invoke-GitLeaks' `
    -CommandName 'gitleaks' `
    -InstallHint 'Install with: scoop install gitleaks'

# trufflehog - Secrets scanner
Register-ToolWrapper `
    -FunctionName 'Invoke-TruffleHog' `
    -CommandName 'trufflehog' `
    -InstallHint 'Install with: scoop install trufflehog'

# osv-scanner - Vulnerability scanner
Register-ToolWrapper `
    -FunctionName 'Invoke-OsvScanner' `
    -CommandName 'osv-scanner' `
    -InstallHint 'Install with: scoop install osv-scanner'
```

### Example 3: Custom Function Names

```powershell
# Register wrappers with custom function names (different from command names)
Register-ToolWrapper `
    -FunctionName 'Invoke-GitLeaks' `
    -CommandName 'gitleaks' `
    -InstallHint 'Install with: scoop install gitleaks'

Register-ToolWrapper `
    -FunctionName 'Invoke-TruffleHog' `
    -CommandName 'trufflehog' `
    -InstallHint 'Install with: scoop install trufflehog'

# Use the functions
Invoke-GitLeaks -Repository "C:\Projects\MyRepo"
Invoke-TruffleHog -Path "C:\Projects\MyRepo"
```

## Advanced Usage

### Command Type Specification

```powershell
# Register wrapper for a specific command type (default is 'Application')
Register-ToolWrapper `
    -FunctionName 'Get-GitStatus' `
    -CommandName 'git' `
    -CommandType 'Application' `
    -InstallHint 'Install with: scoop install git'
```

### Conditional Registration

```powershell
# Only register if Register-ToolWrapper is available
if (Get-Command Register-ToolWrapper -ErrorAction SilentlyContinue) {
    Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install with: scoop install bat'
}
else {
    # Fallback: manual registration
    if (Test-CachedCommand 'bat') {
        Set-AgentModeFunction -Name 'bat' -Body { bat @args }
    }
    else {
        Write-MissingToolWarning -Tool 'bat' -InstallHint 'Install with: scoop install bat'
    }
}
```

## Migration from Old Pattern

### Old Pattern (Manual Wrapper)

```powershell
# ❌ OLD: Manual wrapper with repetitive code
if (Test-CachedCommand 'bat') {
    function global:bat {
        param([Parameter(ValueFromRemainingArguments)]$Arguments)
        bat @Arguments
    }
}
else {
    Write-MissingToolWarning -Tool 'bat' -InstallHint 'Install with: scoop install bat'
}

if (Test-CachedCommand 'fd') {
    function global:fd {
        param([Parameter(ValueFromRemainingArguments)]$Arguments)
        fd @Arguments
    }
}
else {
    Write-MissingToolWarning -Tool 'fd' -InstallHint 'Install with: scoop install fd'
}
```

### New Pattern (Standardized Wrapper)

```powershell
# ✅ NEW: Standardized wrapper registration
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install with: scoop install bat'
Register-ToolWrapper -FunctionName 'fd' -CommandName 'fd' -InstallHint 'Install with: scoop install fd'
```

**Benefits:**

- **65% code reduction** - From 58 lines to 20 lines (as demonstrated in `modern-cli.ps1`)
- **Consistent error handling** - All wrappers use the same warning pattern
- **Easier maintenance** - Single function to update for all wrappers
- **Better performance** - Uses cached command detection

## Integration with Module Loading

### Complete Module Example

```powershell
# ===============================================
# api-tools.ps1
# API development and testing tools
# ===============================================
# Dependencies: bootstrap, env
# Tier: standard

# Load module dependencies first
if (Get-Command Import-FragmentModule -ErrorAction SilentlyContinue) {
    Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('dev-tools-modules', 'api', 'api-helpers.ps1') `
        -Context "Fragment: api-tools (api-helpers.ps1)"
}

# Register tool wrappers
Register-ToolWrapper `
    -FunctionName 'Invoke-Bruno' `
    -CommandName 'bruno' `
    -InstallHint 'Install with: scoop install bruno'

Register-ToolWrapper `
    -FunctionName 'Invoke-Hurl' `
    -CommandName 'hurl' `
    -InstallHint 'Install with: scoop install hurl'

Register-ToolWrapper `
    -FunctionName 'Start-HttpToolkit' `
    -CommandName 'httptoolkit' `
    -InstallHint 'Install with: scoop install httptoolkit'
```

## Error Handling

### Standard Error Handling

The `Register-ToolWrapper` function handles errors automatically:

- **Missing tool**: Displays warning with install hint (does not throw error)
- **Function already exists**: Returns `$false` (idempotent)
- **Invalid parameters**: Returns `$false` silently

### Custom Error Handling

```powershell
# Register wrapper and check result
$success = Register-ToolWrapper `
    -FunctionName 'bat' `
    -CommandName 'bat' `
    -InstallHint 'Install with: scoop install bat'

if (-not $success) {
    Write-Warning "Failed to register bat wrapper (function may already exist)"
}
```

## Best Practices

### 1. Use Descriptive Function Names

```powershell
# ✅ GOOD: Descriptive function names
Register-ToolWrapper -FunctionName 'Invoke-GitLeaks' -CommandName 'gitleaks' -InstallHint '...'
Register-ToolWrapper -FunctionName 'Invoke-TruffleHog' -CommandName 'trufflehog' -InstallHint '...'

# ❌ AVOID: Generic names
Register-ToolWrapper -FunctionName 'tool1' -CommandName 'gitleaks' -InstallHint '...'
```

### 2. Provide Helpful Install Hints

```powershell
# ✅ GOOD: Specific install instructions
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install with: scoop install bat'

# ❌ AVOID: Vague hints
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install the tool'
```

### 3. Group Related Tools

```powershell
# Group related tools together
# Security tools
Register-ToolWrapper -FunctionName 'Invoke-GitLeaks' -CommandName 'gitleaks' -InstallHint '...'
Register-ToolWrapper -FunctionName 'Invoke-TruffleHog' -CommandName 'trufflehog' -InstallHint '...'

# API tools
Register-ToolWrapper -FunctionName 'Invoke-Bruno' -CommandName 'bruno' -InstallHint '...'
Register-ToolWrapper -FunctionName 'Invoke-Hurl' -CommandName 'hurl' -InstallHint '...'
```

### 4. Use Custom Warnings When Needed

```powershell
# Use custom warnings for clarity when command name differs from tool name
Register-ToolWrapper `
    -FunctionName 'http' `
    -CommandName 'http' `
    -WarningMessage 'httpie (http) not found' `
    -InstallHint 'Install with: scoop install httpie'
```

## Using Requirements for Install Hints

### Overview

Instead of hardcoding install hints, you can use the `Get-ToolInstallHint` function from `Command.psm1` to dynamically resolve install commands from the centralized requirements system. This provides:

- **Platform-specific install commands** - Automatically resolves Windows/Linux/macOS commands
- **Centralized maintenance** - Update install commands in one place (`requirements/external-tools/*.psd1`)
- **Consistent formatting** - All hints follow the same "Install with: ..." pattern
- **Fallback support** - Falls back to default commands if requirements aren't available

### Basic Usage with Requirements

```powershell
# Import Command module for Get-ToolInstallHint
if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
    $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
        Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
    }
    else {
        Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
    }

    if ($repoRoot) {
        $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
        if (Test-Path -LiteralPath $commandModulePath) {
            Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
        }
    }
}

# Use Get-ToolInstallHint to get install hint from requirements
$installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
    $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
        Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
    }
    else {
        $null
    }
    Get-ToolInstallHint -ToolName 'gitleaks' -RepoRoot $repoRoot
}
else {
    "Install with: scoop install gitleaks"
}

# Use with Write-MissingToolWarning
if (-not (Test-CachedCommand 'gitleaks')) {
    if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
        Write-MissingToolWarning -Tool 'gitleaks' -InstallHint $installHint
    }
    else {
        Write-Warning "gitleaks not found. $installHint"
    }
    return $null
}
```

### Complete Example: Security Tools Module

```powershell
# ===============================================
# security-tools.ps1
# Security scanning and analysis tools
# ===============================================
# Dependencies: bootstrap, env
# Tier: standard

try {
    # Idempotency check
    if (Get-Command Test-FragmentLoaded -ErrorAction SilentlyContinue) {
        if (Test-FragmentLoaded -FragmentName 'security-tools') { return }
    }

    # Import Command module for Get-ToolInstallHint
    if (-not (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue)) {
        $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
            Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
        }
        else {
            Split-Path -Parent (Split-Path -Parent $PSScriptRoot)
        }

        if ($repoRoot) {
            $commandModulePath = Join-Path $repoRoot 'scripts' 'lib' 'utilities' 'Command.psm1'
            if (Test-Path -LiteralPath $commandModulePath) {
                Import-Module $commandModulePath -DisableNameChecking -ErrorAction SilentlyContinue
            }
        }
    }

    # Gitleaks wrapper
    function Invoke-GitLeaksScan {
        param(
            [string]$RepositoryPath,
            [string]$ReportPath
        )

        if (-not (Test-CachedCommand 'gitleaks')) {
            $installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
                $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
                    Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
                }
                else {
                    $null
                }
                Get-ToolInstallHint -ToolName 'gitleaks' -RepoRoot $repoRoot
            }
            else {
                "Install with: scoop install gitleaks"
            }
            if (Get-Command Write-MissingToolWarning -ErrorAction SilentlyContinue) {
                Write-MissingToolWarning -Tool 'gitleaks' -InstallHint $installHint
            }
            else {
                Write-Warning "gitleaks not found. $installHint"
            }
            return $null
        }

        # Tool implementation...
    }
}
catch {
    Write-ProfileError -ErrorRecord $_ -Context "Fragment: security-tools"
}
```

### Requirements File Structure

Create a requirements file for your tools (e.g., `requirements/external-tools/security-tools.psd1`):

```powershell
@{
    ExternalTools = @{
        'gitleaks' = @{
            Version        = 'latest'
            Description    = 'Find secrets in git repositories'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install gitleaks'
                Linux   = 'See: https://github.com/gitleaks/gitleaks'
                MacOS   = 'brew install gitleaks'
            }
        }
        'trufflehog' = @{
            Version        = 'latest'
            Description    = 'Find secrets in code and history'
            Required       = $false
            InstallCommand = @{
                Windows = 'scoop install trufflehog'
                Linux   = 'See: https://github.com/trufflesecurity/trufflehog'
                MacOS   = 'brew install trufflehog'
            }
        }
    }
}
```

Then load it in `requirements/load-requirements.ps1`:

```powershell
# Security Tools (automated loading)
$securityToolsPath = Join-Path $scriptDir 'external-tools' 'security-tools.psd1'
if (Test-Path $securityToolsPath) {
    try {
        $securityToolsConfig = Import-PowerShellDataFile $securityToolsPath -ErrorAction Stop
        if ($securityToolsConfig.ExternalTools) {
            foreach ($tool in $securityToolsConfig.ExternalTools.Keys) {
                $ExternalTools[$tool] = $securityToolsConfig.ExternalTools[$tool]
            }
        }
    }
    catch {
        Write-Warning "Failed to load Security tools from $securityToolsPath : $($_.Exception.Message)"
    }
}
```

### Benefits of Using Get-ToolInstallHint

1. **Centralized Configuration** - All install commands in one place
2. **Platform Awareness** - Automatically resolves platform-specific commands
3. **Easy Updates** - Change install command once, affects all usages
4. **Consistent Formatting** - All hints follow "Install with: ..." pattern
5. **Graceful Fallback** - Works even if requirements aren't loaded

### When to Use Get-ToolInstallHint vs Hardcoded Hints

**Use `Get-ToolInstallHint` when:**

- Tool has platform-specific install commands
- Tool is defined in requirements system
- You want centralized maintenance
- Tool may have different install methods (scoop, brew, apt, etc.)

**Use hardcoded hints when:**

- Tool has a single, universal install command
- Tool is not in requirements system
- You need maximum simplicity for simple wrappers

### Integration with Register-ToolWrapper

You can combine both patterns:

```powershell
# Get install hint from requirements
$installHint = if (Get-Command Get-ToolInstallHint -ErrorAction SilentlyContinue) {
    $repoRoot = if (Get-Command Get-RepoRoot -ErrorAction SilentlyContinue) {
        Get-RepoRoot -ScriptPath $PSScriptRoot -ErrorAction SilentlyContinue
    }
    else {
        $null
    }
    Get-ToolInstallHint -ToolName 'gitleaks' -RepoRoot $repoRoot
}
else {
    "Install with: scoop install gitleaks"
}

# Use with Register-ToolWrapper
Register-ToolWrapper `
    -FunctionName 'Invoke-GitLeaksScan' `
    -CommandName 'gitleaks' `
    -InstallHint $installHint
```

## Notes

- `Register-ToolWrapper` uses `Test-CachedCommand` internally for fast command detection
- Functions are registered using `Set-AgentModeFunction` for idempotent registration
- Missing tools display warnings but do not throw errors (graceful degradation)
- All wrappers automatically pass through arguments using `@args`
- The function is backward compatible - check for availability before using
- `Get-ToolInstallHint` is available in `scripts/lib/utilities/Command.psm1` and can be imported by any fragment
- `Get-ToolInstallHint` automatically uses `Resolve-InstallCommand` for platform-specific resolution
- Requirements are cached by `Import-Requirements`, so multiple calls to `Get-ToolInstallHint` are efficient
