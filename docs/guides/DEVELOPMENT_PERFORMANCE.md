# Development Performance Optimization Guide

This guide is specifically for **developers working on the profile itself**. It focuses on speeding up your development workflow while keeping all features available for testing.

## The Problem

As a profile developer, you need:

- ✅ All features available for testing
- ✅ Fast reload cycles when iterating on code
- ✅ Ability to test specific fragments without loading everything
- ✅ Quick feedback when making changes

But you're experiencing:

- ❌ Slow profile reloads (2-5 seconds)
- ❌ Time wasted waiting for full profile loads
- ❌ Can't easily test fragments in isolation

## Solution: Development Mode

### Enable Development Mode

Create a `.env` file in your profile root (or set environment variables):

```powershell
# .env file for development
PS_PROFILE_DEV_MODE=1
PS_PROFILE_SKIP_UPDATES=1
PS_PROFILE_SKIP_PROMPT_INIT=0
PS_PROFILE_FAST_RELOAD=1
```

Or set temporarily in your session:

```powershell
$env:PS_PROFILE_DEV_MODE = '1'
$env:PS_PROFILE_SKIP_UPDATES = '1'
$env:PS_PROFILE_FAST_RELOAD = '1'
```

### What Development Mode Does

When `PS_PROFILE_DEV_MODE=1` is set:

1. **Skips expensive operations:**

   - Profile update checks (saves 100-500ms)
   - Git commit hash calculation (saves 50-200ms)
   - Prompt initialization delays (saves 100-300ms)

2. **Uses cached results:**

   - Module path cache persists across reloads
   - Fragment dependency cache persists
   - Command existence cache persists

3. **Faster reloads:**
   - `Reload-Profile` uses fast reload mode
   - Skips validation that's not needed during development

## Fast Reload Function

Use the enhanced reload function for faster iteration:

```powershell
# Fast reload (skips expensive operations)
Reload-Profile -Fast

# Or use the alias
reload-fast
```

**Expected Improvement:** 30-50% faster reloads (1-2 seconds instead of 2-5 seconds)

### What Fast Reload Skips

- Profile update checks
- Git status checks
- Prompt re-initialization (if already loaded)
- Expensive validation steps
- Module path re-validation (uses cache)

## Working on Specific Fragments

### Test a Single Fragment

Instead of reloading the entire profile, test just the fragment you're working on:

```powershell
# Load just one fragment for testing
. profile.d/files.ps1

# Or use the helper function
Test-Fragment -FragmentName 'files'
```

### Isolated Fragment Testing

Create a test script that loads only what you need:

```powershell
# test-fragment.ps1
param([string]$FragmentName)

# Load bootstrap first (required)
. profile.d/bootstrap.ps1

# Load dependencies
. profile.d/env.ps1

# Load the fragment you're testing
. "profile.d/$FragmentName.ps1"

# Test your changes
# ... your test code ...
```

Run it:

```powershell
pwsh -NoProfile -File test-fragment.ps1 -FragmentName 'files'
```

## Development Workflow Optimizations

### 1. Use Separate PowerShell Sessions

Keep one session for development (with fast reload) and one for testing (full profile):

```powershell
# Development session (fast)
$env:PS_PROFILE_DEV_MODE = '1'
$env:PS_PROFILE_FAST_RELOAD = '1'
. $PROFILE

# Testing session (full profile, in separate terminal)
# No dev mode - test with full profile load
```

### 2. Conditional Loading Based on What You're Working On

Create a development configuration that loads only what you need:

```json
// .profile-fragments.json (development)
{
  "disabled": [
    // Disable fragments you're not currently working on
    "angular",
    "ansible",
    "azure"
    // ... etc
  ],
  "performance": {
    "parallelDependencyParsing": true
  }
}
```

### 3. Use Fragment-Specific Testing

When working on a specific fragment, disable others:

```powershell
# Working on files.ps1? Disable other heavy fragments temporarily
$env:PS_PROFILE_DISABLED_FRAGMENTS = 'git,containers,utilities'
. $PROFILE
```

### 4. Hot Reload for Active Development

When actively developing, use hot reload to reload just changed fragments:

```powershell
# Reload just the fragment you changed
Reload-Fragment -FragmentName 'files'

# Or reload multiple fragments
Reload-Fragment -FragmentName 'files','utilities'
```

## Performance Benchmarks

### Measure Your Development Load Time

```powershell
# Benchmark with dev mode
$env:PS_PROFILE_DEV_MODE = '1'
Measure-Command { . $PROFILE }

# Compare to normal mode
$env:PS_PROFILE_DEV_MODE = $null
Measure-Command { . $PROFILE }
```

### Track Fragment Load Times

```powershell
# Enable timing
$env:PS_PROFILE_DEBUG = '3'
. $PROFILE

# See which fragments are slow
$global:PSProfileFragmentTimes |
    Sort-Object Duration -Descending |
    Select-Object -First 10
```

## Development-Specific Environment Variables

Add these to your `.env` file for development:

```powershell
# Development mode (enables optimizations)
PS_PROFILE_DEV_MODE=1

# Skip expensive operations
PS_PROFILE_SKIP_UPDATES=1
PS_PROFILE_SKIP_PROMPT_INIT=0  # Keep prompt, but skip delays

# Fast reload mode
PS_PROFILE_FAST_RELOAD=1

# Disable fragments you're not working on
PS_PROFILE_DISABLED_FRAGMENTS=angular,ansible,azure

# Enable debug for development
PS_PROFILE_DEBUG=1

# Skip local overrides (if not using)
PS_PROFILE_ENABLE_LOCAL_OVERRIDES=0
```

## Quick Development Shortcuts

### Reload Profile (Fast)

```powershell
reload-fast    # Fast reload (skips expensive operations)
reload         # Normal reload
```

### Edit and Reload Cycle

```powershell
# Edit fragment
code profile.d/files.ps1

# Fast reload to test
reload-fast

# Or reload just that fragment
Reload-Fragment -FragmentName 'files'
```

### Test Fragment in Isolation

```powershell
# Load just bootstrap + your fragment
. profile.d/bootstrap.ps1
. profile.d/env.ps1
. profile.d/files.ps1  # Your fragment

# Test it
# ... your test code ...
```

## Advanced: Fragment Development Mode

For intensive fragment development, create a minimal test environment:

```powershell
# fragment-dev.ps1 - Minimal environment for fragment testing
param([string]$FragmentName)

# Load only essentials
. profile.d/bootstrap.ps1
. profile.d/env.ps1

# Load your fragment
. "profile.d/$FragmentName.ps1"

# Your fragment is now loaded with minimal overhead
Write-Host "Fragment $FragmentName loaded. Test your changes now." -ForegroundColor Green
```

Usage:

```powershell
pwsh -NoProfile -File fragment-dev.ps1 -FragmentName 'files'
```

## Tips for Faster Development

1. **Use Fast Reload** - Always use `reload-fast` during active development
2. **Disable Unused Fragments** - Temporarily disable fragments you're not working on
3. **Test in Isolation** - Test fragments individually before full profile test
4. **Keep Dev Mode On** - Set `PS_PROFILE_DEV_MODE=1` in your `.env` file
5. **Use Separate Sessions** - One for dev (fast), one for testing (full)
6. **Cache Persists** - Module path cache persists, so reloads get faster
7. **Skip Update Checks** - Set `PS_PROFILE_SKIP_UPDATES=1` during development

## Expected Performance Improvements

With development mode enabled:

- **Initial Load:** 1-2 seconds (vs 2-5 seconds normal)
- **Fast Reload:** 0.5-1 second (vs 2-5 seconds normal)
- **Fragment-Only Load:** 0.1-0.5 seconds (for single fragment)

## Troubleshooting

### Profile Still Slow?

1. **Check what's loading:**

   ```powershell
   $env:PS_PROFILE_DEBUG = '3'
   . $PROFILE
   $global:PSProfileFragmentTimes | Sort-Object Duration -Descending
   ```

2. **Verify dev mode is enabled:**

   ```powershell
   $env:PS_PROFILE_DEV_MODE
   # Should be '1'
   ```

3. **Clear caches if needed:**

   ```powershell
   Clear-ModulePathCache
   ```

4. **Check for expensive fragments:**
   ```powershell
   # Look for fragments that load many modules
   Select-String -Path profile.d/*.ps1 -Pattern 'Import-FragmentModule' |
       Group-Object Path |
       Sort-Object Count -Descending
   ```

## Related Documentation

- [PROFILE_LOAD_TIME_OPTIMIZATION.md](./PROFILE_LOAD_TIME_OPTIMIZATION.md) - General optimization guide
- [DEVELOPMENT.md](./DEVELOPMENT.md) - Development workflow guide
- [PROFILE_DEBUG.md](../../PROFILE_DEBUG.md) - Debugging and instrumentation
