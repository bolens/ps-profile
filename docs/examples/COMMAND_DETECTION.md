# Using Standardized Command Detection

This guide demonstrates how to use `Test-CachedCommand` for fast, cached command detection in fragments and modules.

## Overview

`Test-CachedCommand` provides:

- **Cached detection** - Results are cached for performance
- **Fast lookups** - Avoids repeated `Get-Command` calls
- **Consistent API** - Standardized across all fragments
- **Performance optimization** - Reduces startup time impact

## Basic Usage

### Simple Command Detection

```powershell
# Check if a command is available
if (Test-CachedCommand 'docker') {
    Write-Host "Docker is available"
    docker --version
}
else {
    Write-Warning "Docker is not installed"
}
```

### Conditional Function Registration

```powershell
# Register functions only when tools are available
if (Test-CachedCommand 'bat') {
    Set-AgentModeFunction -Name 'bat' -Body { bat @args }
    Set-AgentModeAlias -Name 'cat' -Target 'bat'
}
```

### Multiple Command Checks

```powershell
# Check multiple commands
$tools = @('docker', 'podman', 'kubectl')
$available = $tools | Where-Object { Test-CachedCommand $_ }

if ($available.Count -gt 0) {
    Write-Host "Available tools: $($available -join ', ')"
}
```

## Real-World Examples

### Example 1: Container Engine Detection

```powershell
# Detect available container engine (prefer Docker, fallback to Podman)
function Get-ContainerEngine {
    if (Test-CachedCommand 'docker') {
        return 'docker'
    }
    elseif (Test-CachedCommand 'podman') {
        return 'podman'
    }
    else {
        return $null
    }
}

$engine = Get-ContainerEngine
if ($engine) {
    Write-Host "Using container engine: $engine"
    & $engine ps
}
else {
    Write-Warning "No container engine found. Install Docker or Podman."
}
```

### Example 2: Tool Wrapper with Detection

```powershell
# Create a wrapper function that checks for tool availability
function Invoke-GitLeaks {
    <#
    .SYNOPSIS
        Scans a repository for secrets using gitleaks.
    #>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Repository
    )

    if (Test-CachedCommand 'gitleaks') {
        gitleaks detect --source $Repository
    }
    else {
        Write-MissingToolWarning -Tool 'gitleaks' -InstallHint 'Install with: scoop install gitleaks'
    }
}

# Register the function
if (Get-Command Set-AgentModeFunction -ErrorAction SilentlyContinue) {
    Set-AgentModeFunction -Name 'Invoke-GitLeaks' -Body ${function:Invoke-GitLeaks}
}
```

### Example 3: Conditional Module Loading

```powershell
# Load modules based on tool availability
$tools = @{
    'docker' = @('container-modules', 'docker-helpers.ps1')
    'podman' = @('container-modules', 'podman-helpers.ps1')
    'kubectl' = @('k8s-modules', 'kubectl-helpers.ps1')
}

foreach ($tool in $tools.Keys) {
    if (Test-CachedCommand $tool) {
        $modulePath = $tools[$tool]
        Import-FragmentModule `
            -FragmentRoot $PSScriptRoot `
            -ModulePath $modulePath `
            -Context "Fragment: containers ($($modulePath[-1]))"
    }
}
```

### Example 4: Feature Detection

```powershell
# Detect available features and enable them
$features = @{
    'GitHub CLI' = Test-CachedCommand 'gh'
    'Docker' = Test-CachedCommand 'docker'
    'Kubernetes' = Test-CachedCommand 'kubectl'
    'Terraform' = Test-CachedCommand 'terraform'
}

Write-Host "Available features:" -ForegroundColor Cyan
foreach ($feature in $features.Keys) {
    $status = if ($features[$feature]) { "✓" } else { "✗" }
    $color = if ($features[$feature]) { "Green" } else { "Red" }
    Write-Host "  $status $feature" -ForegroundColor $color
}
```

## Advanced Usage

### Command Type Specification

```powershell
# Check for specific command types
if (Test-CachedCommand 'git' -CommandType 'Application') {
    Write-Host "Git executable found"
}

if (Test-CachedCommand 'Get-Process' -CommandType 'Cmdlet') {
    Write-Host "Get-Process cmdlet available"
}

if (Test-CachedCommand 'MyFunction' -CommandType 'Function') {
    Write-Host "MyFunction is defined"
}
```

### Cache Management

```powershell
# Test-CachedCommand automatically caches results
# First call: checks command availability
$first = Test-CachedCommand 'docker'  # May take a few milliseconds

# Subsequent calls: uses cache (instant)
$second = Test-CachedCommand 'docker'  # Instant (cached)
$third = Test-CachedCommand 'docker'  # Instant (cached)

# Cache persists for the session
```

## Migration from Old Pattern

### Old Pattern (Test-HasCommand)

```powershell
# ❌ OLD: Using deprecated Test-HasCommand
if (Test-HasCommand 'docker') {
    docker ps
}
```

### New Pattern (Test-CachedCommand)

```powershell
# ✅ NEW: Using standardized Test-CachedCommand
if (Test-CachedCommand 'docker') {
    docker ps
}
```

**Benefits:**

- **Performance**: Cached results are instant
- **Consistency**: Same API across all fragments
- **Future-proof**: No deprecated function dependencies

## Integration Patterns

### With Register-ToolWrapper

```powershell
# Register-ToolWrapper uses Test-CachedCommand internally
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint '...'

# The wrapper function automatically checks for command availability
bat file.txt  # Works if bat is installed, shows warning if not
```

### With Set-AgentModeFunction

```powershell
# Create function that checks for command
function Invoke-Docker {
    if (Test-CachedCommand 'docker') {
        docker @args
    }
    else {
        Write-MissingToolWarning -Tool 'docker' -InstallHint 'Install with: scoop install docker'
    }
}

Set-AgentModeFunction -Name 'Invoke-Docker' -Body ${function:Invoke-Docker}
```

### With Error Handling

```powershell
# Graceful error handling when command is missing
try {
    if (Test-CachedCommand 'required-tool') {
        required-tool --version
    }
    else {
        throw "required-tool is not installed"
    }
}
catch {
    Write-Error "Failed to use required-tool: $_"
    Write-Host "Install with: scoop install required-tool" -ForegroundColor Yellow
}
```

## Best Practices

### 1. Use Cached Detection

```powershell
# ✅ GOOD: Use Test-CachedCommand (cached)
if (Test-CachedCommand 'docker') {
    docker ps
}

# ❌ AVOID: Direct Get-Command (not cached)
if (Get-Command 'docker' -ErrorAction SilentlyContinue) {
    docker ps
}
```

### 2. Check Before Using

```powershell
# ✅ GOOD: Always check before using
if (Test-CachedCommand 'tool') {
    tool --version
}
else {
    Write-Warning "Tool not available"
}

# ❌ AVOID: Assuming command exists
tool --version  # May fail if tool is not installed
```

### 3. Provide Helpful Messages

```powershell
# ✅ GOOD: Helpful error messages
if (Test-CachedCommand 'docker') {
    docker ps
}
else {
    Write-MissingToolWarning -Tool 'docker' -InstallHint 'Install with: scoop install docker'
}

# ❌ AVOID: Generic error messages
if (-not (Test-CachedCommand 'docker')) {
    Write-Error "Error"  # Not helpful
}
```

### 4. Use in Conditional Loading

```powershell
# ✅ GOOD: Load modules conditionally
if (Test-CachedCommand 'docker') {
    Import-FragmentModule `
        -FragmentRoot $PSScriptRoot `
        -ModulePath @('container-modules', 'docker-helpers.ps1') `
        -Context "Fragment: docker-helpers"
}

# ❌ AVOID: Loading modules unconditionally
Import-FragmentModule ...  # May fail if dependencies are missing
```

## Performance Considerations

### Cache Benefits

```powershell
# First call: actual command check (may take a few milliseconds)
$start = Get-Date
Test-CachedCommand 'docker'  # ~5-10ms
$firstCall = (Get-Date) - $start

# Subsequent calls: cached (instant)
$start = Get-Date
Test-CachedCommand 'docker'  # ~0.1ms (cached)
$secondCall = (Get-Date) - $start

Write-Host "First call: $($firstCall.TotalMilliseconds)ms"
Write-Host "Second call: $($secondCall.TotalMilliseconds)ms"
```

### Batch Checks

```powershell
# Check multiple commands efficiently (all cached after first check)
$tools = @('docker', 'podman', 'kubectl', 'helm', 'terraform')
$available = $tools | Where-Object { Test-CachedCommand $_ }

# All subsequent checks use cache
```

## Notes

- `Test-CachedCommand` caches results for the current PowerShell session
- Cache is automatically managed - no manual cache clearing needed
- Use `Test-CachedCommand` instead of deprecated `Test-HasCommand`
- The function is available from bootstrap, so it can be used in any fragment
- Command detection is case-insensitive on Windows, case-sensitive on Linux/macOS
- Cache persists for the session but is cleared when PowerShell exits
