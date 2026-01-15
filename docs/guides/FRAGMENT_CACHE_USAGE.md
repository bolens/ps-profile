# Fragment Cache Usage Guide

## Overview

The fragment cache system stores parsed fragment results in a SQLite database to dramatically improve profile load times. Cache entries persist between PowerShell sessions.

## Cache Modes

The cache supports two loading modes:

### 1. On-Demand (Default)

**How it works:**

- Cache infrastructure is initialized at startup
- Cache entries are loaded automatically when fragments are parsed
- Each fragment query checks the database and loads entries as needed

**When to use:**

- ✅ Faster startup times
- ✅ You only parse a few fragments at a time
- ✅ You prefer lazy loading
- ✅ You have fewer fragments (< 100)

**Configuration:**

```powershell
# Default behavior - no configuration needed
# Or explicitly disable pre-warming:
PS_PROFILE_PREWARM_CACHE=0
```

### 2. Pre-Warm (Optional)

**How it works:**

- Cache infrastructure is initialized at startup
- All cache entries are loaded from database into memory at startup
- Fragment parsing uses in-memory cache (no database queries)

**When to use:**

- ✅ You have many fragments (100+)
- ✅ You're doing batch operations on many fragments
- ✅ Startup time is less important than parsing performance
- ✅ You want the fastest possible fragment parsing

**Configuration:**

```powershell
# Enable pre-warming:
PS_PROFILE_PREWARM_CACHE=1
```

## Configuration

### Environment Variables

Add to your `.env` file:

```bash
# Fragment cache pre-warming mode
# Values: '1' or 'true' = pre-warm, '0' or 'false' = on-demand (default)
PS_PROFILE_PREWARM_CACHE=0

# Cache database location (optional)
# Default: %LOCALAPPDATA%\PowerShellProfile (Windows) or ~/.cache/powershell-profile (Unix)
# Recommended: Use project-local directory for version control
PS_PROFILE_CACHE_DIR=.cache
```

### Cache Database Location

The cache database is stored at:

- **Default (Windows):** `%LOCALAPPDATA%\PowerShellProfile\fragment-cache.db`
- **Default (Unix):** `~/.cache/powershell-profile/fragment-cache.db`
- **Custom:** Set `PS_PROFILE_CACHE_DIR` to specify a different location

**Recommended:** Use a project-local cache directory (e.g., `.cache/`) so the cache can be shared with your team and version controlled.

## How It Works

### Cache Initialization

1. **Startup:** Cache infrastructure is initialized (in-memory hashtables + SQLite database)
2. **If pre-warming enabled:** All cache entries are loaded from database into memory
3. **If on-demand:** Cache entries load automatically when fragments are parsed

### Cache Storage

Cache entries are stored when fragments are parsed:

- **Content cache:** Stores fragment file content (for regex parsing)
- **AST cache:** Stores parsed function names (for AST parsing)

Entries are keyed by:

- File path (normalized)
- Last write time (for validation)
- Parsing mode (regex or AST)

### Cache Validation

Cache entries are automatically invalidated when:

- Fragment files are modified (last write time changes)
- Parsing mode changes (switching between regex and AST)
- Cache database is cleared

## Performance Impact

### On-Demand Mode

- **Startup:** ~50-100ms (cache initialization only)
- **First parse:** Database query per fragment (~10-50ms per fragment)
- **Subsequent parses:** Database query per fragment (~10-50ms per fragment)

**Best for:** Fast startup, occasional fragment parsing

### Pre-Warm Mode

- **Startup:** ~200-500ms (cache initialization + loading all entries)
- **First parse:** In-memory lookup (~1-5ms per fragment)
- **Subsequent parses:** In-memory lookup (~1-5ms per fragment)

**Best for:** Fast parsing, many fragments, batch operations

## Troubleshooting

### Cache Not Working

1. **Check SQLite availability:**

   ```powershell
   # Should return path to sqlite3 executable
   Get-Command sqlite3 -ErrorAction SilentlyContinue
   ```

2. **Check cache database:**

   ```powershell
   # Get cache database path
   Import-Module .\scripts\lib\fragment\FragmentCache.psm1
   Get-FragmentCacheDbPath
   ```

3. **Check cache statistics:**
   ```powershell
   Import-Module .\scripts\lib\fragment\FragmentCache.psm1
   Get-FragmentCacheStats
   ```

### Cache Not Pre-Warming

1. **Verify pre-warming is enabled:**

   ```powershell
   $env:PS_PROFILE_PREWARM_CACHE  # Should be '1' or 'true'
   ```

2. **Check debug output:**

   ```powershell
   $env:PS_PROFILE_DEBUG = 3
   # Restart PowerShell and look for pre-warming messages
   ```

3. **Verify SQLite is available:**
   - Pre-warming requires SQLite to be installed
   - Falls back to on-demand if SQLite is not available

### Build Cache

The fragment cache can be built/warmed using the `build-fragment-cache.ps1` utility script. This script parses all fragment files to populate both in-memory caches and the SQLite database, ensuring faster subsequent profile loads.

#### Using Task Runners

```powershell
# Using Task
task build-fragment-cache

# Using Make
make build-fragment-cache

# Using npm/pnpm
pnpm run build-fragment-cache
```

#### Direct Script Execution

```powershell
# Build cache for all fragments (default)
pwsh -NoProfile -File scripts\utils\build-fragment-cache.ps1

# Preview what would be built (dry-run)
pwsh -NoProfile -File scripts\utils\build-fragment-cache.ps1 -WhatIf

# Build cache for fragments in a specific directory
pwsh -NoProfile -File scripts\utils\build-fragment-cache.ps1 -FragmentPath "C:\path\to\profile.d"

# Force mode (continue despite errors)
pwsh -NoProfile -File scripts\utils\build-fragment-cache.ps1 -Force

# Use AST parsing (slower but more accurate)
pwsh -NoProfile -File scripts\utils\build-fragment-cache.ps1 -UseAstParsing
```

#### What Gets Built

The script builds cache entries for:

- **Fragment content cache:** Stores fragment file content for regex parsing
- **Fragment AST cache:** Stores parsed function names for AST parsing
- **SQLite database:** Persists cache entries between PowerShell sessions

#### When to Build Cache

Build the cache when:

- You've cleared the cache and want to rebuild it
- You've added new fragments and want to pre-populate the cache
- You want to ensure all fragments are cached for faster profile loads
- You're testing cache behavior

**Note:** The cache is built automatically as fragments are parsed during profile load. Building the cache manually is useful for pre-warming or after clearing the cache.

### Clear Cache

The fragment cache can be cleared using the `clear-fragment-cache.ps1` utility script. This script clears both in-memory caches and the SQLite database file.

#### Using Task Runners

```powershell
# Using Task
task clear-fragment-cache

# Using Make
make clear-fragment-cache

# Using npm/pnpm
pnpm run clear-fragment-cache
```

#### Direct Script Execution

```powershell
# Clear all cache components (default)
pwsh -NoProfile -File scripts\utils\clear-fragment-cache.ps1

# Preview what would be cleared (dry-run)
pwsh -NoProfile -File scripts\utils\clear-fragment-cache.ps1 -WhatIf

# Clear only in-memory caches (leave database intact)
pwsh -NoProfile -File scripts\utils\clear-fragment-cache.ps1 -IncludeDatabase:$false

# Clear only database (leave memory caches intact)
pwsh -NoProfile -File scripts\utils\clear-fragment-cache.ps1 -IncludeMemoryCache:$false

# Force mode (continue despite errors)
pwsh -NoProfile -File scripts\utils\clear-fragment-cache.ps1 -Force
```

#### What Gets Cleared

The script clears:

- **In-memory caches:**
  - `FragmentContentCache` (fragment file content cache for regex parsing)
  - `FragmentAstCache` (AST parsing cache for function definitions)
- **SQLite database:**
  - `fragment-cache.db` file (if it exists)
  - **Both parsing mode caches:**
    - AST parsing cache entries (`ParsingMode='ast'`) - function definitions discovered via AST parsing
    - Regex parsing cache entries (`ParsingMode='regex'`) - commands discovered via regex pattern matching
- **Module state variables:**
  - `PSProfileModuleFileTimes` (module file modification time cache)

**Note:** The database stores cache entries separately for each parsing mode. Clearing the database removes both AST and regex cache entries, ensuring a complete cache reset.

#### Script Features

- **Resilient to failures:** Continues clearing other components even if one fails
- **Dry-run support:** Use `-WhatIf` to preview changes without making them
- **Selective clearing:** Control which components to clear with `-IncludeDatabase` and `-IncludeMemoryCache`
- **Comprehensive logging:** Follows error handling standards with structured logging
- **Statistics:** Reports success/failure counts and detailed statistics at debug level 2+

#### When to Clear Cache

Clear the cache when:

- Fragment files have been modified and you want to force re-parsing
- Cache appears corrupted or stale
- Debugging cache-related issues
- Testing cache behavior
- After major profile changes

**Note:** Clearing the cache will slow down the next profile load as fragments need to be re-parsed and cached. After clearing, you can rebuild the cache using `build-fragment-cache.ps1`.

## Examples

### Enable Pre-Warming

```powershell
# In .env file
PS_PROFILE_PREWARM_CACHE=1
```

### Use Project-Local Cache

```powershell
# In .env file
PS_PROFILE_CACHE_DIR=.cache
```

### Disable Cache (Use In-Memory Only)

```powershell
# Remove or don't install sqlite3
# Cache will fall back to in-memory only (not persistent)
```

## Summary

- **On-demand (default):** Fast startup, cache loads as needed
- **Pre-warm (optional):** Slower startup, faster parsing
- **Configuration:** Single environment variable (`PS_PROFILE_PREWARM_CACHE`)
- **Automatic:** Cache works automatically once initialized
- **Persistent:** Cache survives PowerShell sessions (requires SQLite)
