# SQLite Databases Guide

SQLite databases used for persistent storage in this profile.

## Overview

| Database | File | Purpose | Documentation |
| -------- | ---- | ------- | --------------- |
| Fragment cache | `fragment-cache.db` | Parsed fragment content and AST command caches | [Fragment Cache Usage](FRAGMENT_CACHE_USAGE.md) |
| Command history | `command-history.db` | Cross-session command execution history | This guide (when module available) |
| Performance metrics | `performance-metrics.db` | Startup and operation timing history | This guide (when module available) |
| Test cache | `test-cache.db` | Test result caching for CI | [Testing Guide](TESTING.md) |

All databases live under the profile cache directory:

1. `PS_PROFILE_CACHE_DIR` when set (recommended: project-local `.cache/`)
2. Otherwise platform defaults:
   - Windows: `%LOCALAPPDATA%\PowerShellProfile`
   - Linux/macOS: `~/.cache/powershell-profile` or `$XDG_CACHE_HOME/powershell-profile`

Database files are gitignored. Use `Get-FragmentCacheDbPath` from `FragmentCachePath.psm1` for the fragment cache path.

## Maintenance Scripts

Primary entry points under `scripts/utils/database/`:

```powershell
# Initialize schemas (requires sqlite3 and lib database modules)
pwsh -NoProfile -File scripts/utils/database/initialize-databases.ps1

# Health, optimize, backup, repair, statistics
pwsh -NoProfile -File scripts/utils/database/database-maintenance.ps1 -Action health

# Validate database files and schemas
pwsh -NoProfile -File scripts/utils/database/validate-databases.ps1
```

These scripts import helpers from `scripts/lib/utilities/SqliteDatabase.psm1` and per-database modules under `scripts/lib/database/` when present. They degrade gracefully when optional modules are not installed.

## Fragment Cache (Primary)

The fragment cache is the most actively used SQLite database. It stores:

- **Content cache** — fragment source for regex parsing
- **AST cache** — function and command names from AST parsing

Operations:

```powershell
task build-fragment-cache   # warm cache
task clear-fragment-cache   # reset cache
```

See [Fragment Cache Usage](FRAGMENT_CACHE_USAGE.md) for configuration (`PS_PROFILE_PREWARM_CACHE`, `PS_PROFILE_CACHE_DIR`) and troubleshooting.

## Command History Database

Tracks command execution across sessions when `CommandHistoryDatabase.psm1` is available (loaded by diagnostics performance monitoring).

Typical functions when the module is present:

```powershell
Get-CommandHistory -Limit 50
Get-CommandUsageStats -Limit 20
Clear-CommandHistory -OlderThan (Get-Date).AddMonths(-6)
```

Integrated via `profile.d/diagnostics-modules/monitoring/diagnostics-performance.ps1`.

## Performance Metrics Database

Stores timing data from `Measure-Operation` (`scripts/lib/performance/PerformanceMeasurement.psm1`), `benchmark-startup.ps1`, and test performance monitoring.

## Test Cache Database

The test runner uses `scripts/utils/code-quality/modules/TestCache.psm1`, which prefers `TestCacheDatabase.psm1` when available and falls back to JSON file caching otherwise.

## Database Maintenance

```powershell
# All databases
pwsh -NoProfile -File scripts/utils/database/database-maintenance.ps1 -Action health
pwsh -NoProfile -File scripts/utils/database/database-maintenance.ps1 -Action optimize
pwsh -NoProfile -File scripts/utils/database/database-maintenance.ps1 -Action backup
pwsh -NoProfile -File scripts/utils/database/database-maintenance.ps1 -Action repair
pwsh -NoProfile -File scripts/utils/database/database-maintenance.ps1 -Action statistics -OutputFormat json
```

Target a single database with `-Database command-history`, `-Database performance-metrics`, or `-Database test-cache`.

Low-level SQLite helpers (when `SqliteDatabase.psm1` is available):

```powershell
Import-Module scripts/lib/utilities/SqliteDatabase.psm1
Test-DatabaseIntegrity -DatabasePath (Join-Path $cacheDir 'command-history.db')
Backup-Database -DatabasePath (Join-Path $cacheDir 'command-history.db')
Repair-Database -DatabasePath (Join-Path $cacheDir 'command-history.db') -BackupBeforeRepair
```

## Best Practices

1. Use `PS_PROFILE_CACHE_DIR=.cache` for a project-local, team-shareable cache directory
2. Run `database-maintenance.ps1 -Action health` periodically in long-lived environments
3. Clear or rebuild the fragment cache after large profile refactors (`task clear-fragment-cache`)
4. Back up `.cache/` when preserving metrics history matters

## Related Documentation

- [Fragment Cache Usage](FRAGMENT_CACHE_USAGE.md)
- [Fragment Loading Optimization](FRAGMENT_LOADING_OPTIMIZATION.md)
- [Profile Load Time Optimization](PROFILE_LOAD_TIME_OPTIMIZATION.md)
- [Testing Guide](TESTING.md)
- [ARCHITECTURE.md](../../ARCHITECTURE.md)
