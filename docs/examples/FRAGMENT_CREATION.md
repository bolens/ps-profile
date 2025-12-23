# Creating New Fragments with Modern Patterns

This guide demonstrates how to create new fragments following the modern patterns established in the refactoring plans, including standardized module loading, tool wrappers, and proper dependency declarations.

## Overview

Modern fragments should follow these patterns:

- **Named fragments** - Use descriptive names instead of numbers (e.g., `security-tools.ps1` instead of `76-security-tools.ps1`)
- **Explicit dependencies** - Declare dependencies in fragment header
- **Tier declarations** - Specify fragment tier (core, essential, standard, optional)
- **Standardized module loading** - Use `Import-FragmentModule` for submodules
- **Tool wrapper registration** - Use `Register-ToolWrapper` for external tools
- **Command detection** - Use `Test-CachedCommand` for tool availability
- **Idempotent functions** - Use `Set-AgentModeFunction` and `Set-AgentModeAlias`

## Fragment Structure

### Basic Fragment Template

```powershell
# ===============================================
# fragment-name.ps1
# Brief description of what this fragment provides
# ===============================================
# Dependencies: bootstrap, env
# Tier: standard

# Fragment implementation here
```

### Fragment with Submodules

```powershell
# ===============================================
# containers.ps1
# Container engine helpers (Docker/Podman) and Compose utilities
# ===============================================
# Provides unified container management functions that work with either Docker or Podman.
# Functions automatically detect available engines and prefer Docker, falling back to Podman.
# All helpers are idempotent and check for engine availability before executing commands.
# Dependencies: bootstrap, env
# Tier: standard

# Load container utility modules using standardized module loading
if (Get-Command Import-FragmentModules -ErrorAction SilentlyContinue) {
    try {
        $modules = @(
            @{
                ModulePath = @('container-modules', 'container-helpers.ps1')
                Context = 'Fragment: containers (container-helpers.ps1)'
            },
            @{
                ModulePath = @('container-modules', 'container-compose.ps1')
                Context = 'Fragment: containers (container-compose.ps1)'
            }
        )

        $result = Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules $modules

        if ($env:PS_PROFILE_DEBUG -and $result.FailureCount -gt 0) {
            Write-Verbose "Loaded $($result.SuccessCount) container modules (failed: $($result.FailureCount))"
        }
    }
    catch {
        if ($env:PS_PROFILE_DEBUG) {
            if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
                Write-ProfileError -ErrorRecord $_ -Context "Fragment: containers" -Category 'Fragment'
            }
            else {
                Write-Warning "Failed to load containers fragment: $($_.Exception.Message)"
            }
        }
    }
}
else {
    # Fallback: manual loading for environments where Import-FragmentModules is not yet available
    # ... fallback code ...
}
```

## Real-World Examples

### Example 1: Simple Tool Wrapper Fragment

```powershell
# ===============================================
# modern-cli.ps1
# Modern CLI tools helper functions
# ===============================================
# Modern CLI tool wrappers with command detection
# Dependencies: bootstrap
# Tier: standard

# bat - cat clone with syntax highlighting and Git integration
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install with: scoop install bat'

# fd - find files and directories
Register-ToolWrapper -FunctionName 'fd' -CommandName 'fd' -InstallHint 'Install with: scoop install fd'

# zoxide - smarter cd command
Register-ToolWrapper -FunctionName 'zoxide' -CommandName 'zoxide' -InstallHint 'Install with: scoop install zoxide'

# delta - syntax-highlighting pager for git
Register-ToolWrapper -FunctionName 'delta' -CommandName 'delta' -InstallHint 'Install with: scoop install delta'
```

### Example 2: Security Tools Fragment

```powershell
# ===============================================
# security-tools.ps1
# Security scanning and analysis tools
# ===============================================
# Provides functions for security scanning, secret detection, and vulnerability analysis.
# Dependencies: bootstrap, env
# Tier: standard

# Register tool wrappers
Register-ToolWrapper `
    -FunctionName 'Invoke-GitLeaks' `
    -CommandName 'gitleaks' `
    -InstallHint 'Install with: scoop install gitleaks'

Register-ToolWrapper `
    -FunctionName 'Invoke-TruffleHog' `
    -CommandName 'trufflehog' `
    -InstallHint 'Install with: scoop install trufflehog'

Register-ToolWrapper `
    -FunctionName 'Invoke-OsvScanner' `
    -CommandName 'osv-scanner' `
    -InstallHint 'Install with: scoop install osv-scanner'

# Custom function with additional logic
function Invoke-SecurityScan {
    <#
    .SYNOPSIS
        Scans a repository for security issues using multiple tools.

    .DESCRIPTION
        Runs gitleaks, trufflehog, and osv-scanner on the specified repository.

    .PARAMETER Repository
        Path to the repository to scan.

    .EXAMPLE
        Invoke-SecurityScan -Repository "C:\Projects\MyRepo"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Repository
    )

    if (-not (Test-Path $Repository)) {
        Write-Error "Repository path does not exist: $Repository"
        return
    }

    Write-Host "Scanning repository: $Repository" -ForegroundColor Cyan

    # Run gitleaks
    if (Test-CachedCommand 'gitleaks') {
        Write-Host "Running gitleaks..." -ForegroundColor Yellow
        Invoke-GitLeaks detect --source $Repository
    }

    # Run trufflehog
    if (Test-CachedCommand 'trufflehog') {
        Write-Host "Running trufflehog..." -ForegroundColor Yellow
        Invoke-TruffleHog filesystem $Repository
    }

    # Run osv-scanner
    if (Test-CachedCommand 'osv-scanner') {
        Write-Host "Running osv-scanner..." -ForegroundColor Yellow
        Invoke-OsvScanner --lockfile "$Repository/package-lock.json"
    }

    Write-Host "Security scan complete." -ForegroundColor Green
}

# Register the custom function
if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
    Set-AgentModeFunction -Name 'Invoke-SecurityScan' -Body ${function:Invoke-SecurityScan}
}
```

### Example 3: Fragment with Custom Functions

```powershell
# ===============================================
# git-enhanced.ps1
# Enhanced Git tools
# ===============================================
# Provides enhanced Git functionality beyond basic git commands.
# Dependencies: bootstrap, env, git
# Tier: standard

# Load Git module dependencies first
if (Get-Command Import-FragmentModule -ErrorAction SilentlyContinue) {
    Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('git-modules', 'core', 'git-helpers.ps1') `
        -Context "Fragment: git-enhanced (git-helpers.ps1)" `
        -Dependencies @('bootstrap', 'env', 'git')
}

# Custom function: Generate changelog
function New-GitChangelog {
    <#
    .SYNOPSIS
        Generates a changelog using git-cliff.

    .DESCRIPTION
        Uses git-cliff to generate a changelog from Git commits.

    .PARAMETER Output
        Output file path for the changelog.

    .EXAMPLE
        New-GitChangelog -Output "CHANGELOG.md"
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Output
    )

    if (Test-CachedCommand 'git-cliff') {
        git-cliff -o $Output
    }
    else {
        Write-MissingToolWarning -Tool 'git-cliff' -InstallHint 'Install with: scoop install git-cliff'
    }
}

# Register custom functions
if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
    Set-AgentModeFunction -Name 'New-GitChangelog' -Body ${function:New-GitChangelog}
}

# Register aliases
if (Get-Command Set-AgentModeAlias -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'gchangelog' -Target 'New-GitChangelog'
}
```

### Example 4: Fragment with Lazy Loading

```powershell
# ===============================================
# expensive-tools.ps1
# Expensive tools with lazy loading
# ===============================================
# Tools that are expensive to initialize are loaded lazily on first use.
# Dependencies: bootstrap, env
# Tier: optional

# Register lazy-loading function
Register-LazyFunction -Name 'Enable-ExpensiveTools' -Initializer {
    # Expensive initialization happens here
    Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('expensive-modules', 'heavy-tool.ps1') `
        -Context "Fragment: expensive-tools (heavy-tool.ps1)" `
        -Required

    # Register tool wrappers after module loads
    Register-ToolWrapper -FunctionName 'heavy-tool' -CommandName 'heavy-tool' -InstallHint '...'

    Write-Verbose "Expensive tools initialized"
} -Alias 'enable-heavy'
```

## Fragment Tiers

### Core Tier

```powershell
# ===============================================
# bootstrap.ps1
# Core bootstrap and initialization
# ===============================================
# Dependencies: (none)
# Tier: core
```

### Essential Tier

```powershell
# ===============================================
# env.ps1
# Environment configuration
# ===============================================
# Dependencies: bootstrap
# Tier: essential
```

### Standard Tier

```powershell
# ===============================================
# git.ps1
# Git helpers and utilities
# ===============================================
# Dependencies: bootstrap, env
# Tier: standard
```

### Optional Tier

```powershell
# ===============================================
# game-emulators.ps1
# Game console emulators
# ===============================================
# Dependencies: bootstrap, env
# Tier: optional
```

## Error Handling Patterns

### Standard Error Handling

```powershell
# Wrap risky operations in try-catch
try {
    if (Get-Command Import-FragmentModule -ErrorAction SilentlyContinue) {
        Import-FragmentModule `
            -FragmentRoot $PSScriptRoot `
            -ModulePath @('modules', 'example.ps1') `
            -Context "Fragment: example"
    }
}
catch {
    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $_ -Context "Fragment: example" -Category 'Fragment'
        }
        else {
            Write-Warning "Failed to load example fragment: $($_.Exception.Message)"
        }
    }
}
```

### Graceful Degradation

```powershell
# Check for function availability before using
if (Get-Command Register-ToolWrapper -ErrorAction SilentlyContinue) {
    Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint '...'
}
else {
    # Fallback for environments where Register-ToolWrapper is not yet available
    if (Test-CachedCommand 'bat') {
        Set-AgentModeFunction -Name 'bat' -Body { bat @args }
    }
    else {
        Write-MissingToolWarning -Tool 'bat' -InstallHint '...'
    }
}
```

## Best Practices

### 1. Use Descriptive Fragment Names

```powershell
# ✅ GOOD: Descriptive names
security-tools.ps1
api-tools.ps1
git-enhanced.ps1

# ❌ AVOID: Numbered names (legacy pattern)
76-security-tools.ps1
77-api-tools.ps1
```

### 2. Declare Dependencies Explicitly

```powershell
# ✅ GOOD: Explicit dependencies
# Dependencies: bootstrap, env, git

# ❌ AVOID: Implicit dependencies (rely on loading order)
```

### 3. Use Standardized Functions

```powershell
# ✅ GOOD: Use standardized functions
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint '...'
Import-FragmentModule -FragmentRoot $PSScriptRoot -ModulePath @(...) -Context "..."
Test-CachedCommand 'tool'

# ❌ AVOID: Manual implementations
if (Get-Command 'bat' -ErrorAction SilentlyContinue) { ... }
```

### 4. Provide Comprehensive Documentation

```powershell
# ✅ GOOD: Comprehensive header
# ===============================================
# fragment-name.ps1
# Brief description
# ===============================================
# Detailed description of what this fragment provides.
# Additional context and usage information.
# Dependencies: bootstrap, env
# Tier: standard
```

### 5. Use Idempotent Registration

```powershell
# ✅ GOOD: Idempotent registration
Set-AgentModeFunction -Name 'MyFunction' -Body ${function:MyFunction}
Set-AgentModeAlias -Name 'mf' -Target 'MyFunction'

# ❌ AVOID: Direct function/alias creation
function global:MyFunction { ... }
Set-Alias -Name 'mf' -Value 'MyFunction'
```

## Migration Checklist

When creating a new fragment or migrating an existing one:

- [ ] Use descriptive fragment name (not numbered)
- [ ] Add fragment header with description
- [ ] Declare dependencies explicitly
- [ ] Specify fragment tier
- [ ] Use `Import-FragmentModule` for submodules
- [ ] Use `Register-ToolWrapper` for external tools
- [ ] Use `Test-CachedCommand` for command detection
- [ ] Use `Set-AgentModeFunction` for function registration
- [ ] Use `Set-AgentModeAlias` for alias registration
- [ ] Add comprehensive error handling
- [ ] Include comment-based help for all functions
- [ ] Test fragment loading and dependencies
- [ ] Verify graceful degradation when tools are missing

## Notes

- Fragments should be idempotent (safe to source multiple times)
- Use lazy loading for expensive operations
- Always check for function availability before using (backward compatibility)
- Provide fallback implementations when possible
- Follow the fragment naming convention (descriptive names, not numbers)
- Dependencies are resolved automatically by the profile loader
- Tier declarations help organize fragments by importance
