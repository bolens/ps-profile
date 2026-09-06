# SQLite databases guide

[Documentation](../README.md) · [Architecture](../../ARCHITECTURE.md) ·
[Fragment cache usage](FRAGMENT_CACHE_USAGE.md) · [Testing](TESTING.md)

SQLite integration is optional. This checkout includes cache-path helpers and
maintenance entry points, but it does not contain `SqliteDatabase.psm1` or the
per-database modules expected under `scripts/lib/database/`. Do not interpret
those entry points as proof that all named databases can be initialized or used.

## Overview

The intended stores separate parsed-fragment caches, command history, performance
metrics, and test results. Cache data may be replaceable from source, while history
and retained metrics can be user data. Keep that distinction when clearing,
backing up, or restoring a profile cache directory.

[PlatformPaths.psm1](../../scripts/lib/core/PlatformPaths.psm1) owns cache-directory
selection. [FragmentCachePath.psm1](../../scripts/lib/fragment/FragmentCachePath.psm1)
resolves the fragment database path and honors the shared cache-directory policy.
A path helper does not establish that the database implementation exists.

## Maintenance scripts

[Database scripts](../../scripts/utils/database/) describe their parameters in
source help. Check their required modules before running initialization, backup,
repair, or migration. Installing `sqlite3` alone does not supply the missing
PowerShell modules. Maintenance reports a setup error when required utilities
are unavailable. Do not use a live profile to test that failure path.

## Fragment cache (primary)

The fragment cache path is defined by
[Get-FragmentCacheDbPath](../../scripts/lib/fragment/FragmentCachePath.psm1).
[Build](../../scripts/utils/build-fragment-cache.ps1) and
[clear](../../scripts/utils/clear-fragment-cache.ps1) scripts own the available
cache operations. Follow [fragment cache usage](FRAGMENT_CACHE_USAGE.md) for
startup integration, and verify backend availability before claiming persistent
SQLite caching is active.

## Command history database

[Diagnostics monitoring](../../profile.d/diagnostics-modules/monitoring/diagnostics-performance.ps1)
contains optional command-history integration. `CommandHistoryDatabase.psm1` is
not present in this checkout. Do not advertise its functions as installed commands
or assume cross-session records exist. Treat any externally supplied history
backend as sensitive user state.

## Performance metrics database

[Performance measurement](../../scripts/lib/performance/PerformanceMeasurement.psm1)
and [metrics history](../../scripts/lib/metrics/MetricsHistory.psm1) own metric
collection and persistence behavior. The optional `PerformanceMetricsDatabase.psm1`
backend is absent. Read the actual fallback before choosing a backup or migration
procedure.

## Test cache database

[TestCache.psm1](../../scripts/utils/code-quality/modules/TestCache.psm1) tries the
optional `TestCacheDatabase.psm1` backend and falls back to JSON. That database
module is absent here. Tests must cover the selected backend without depending
on personal cache contents or a successful database initialization.

## Database maintenance

Before introducing a backend, define its schema owner, compatibility with retained
records, migration behavior, and restore procedure. Test failure and rollback with
disposable data. A code rollback does not undo database writes. Preserve history
and metrics before any destructive repair or reset.

## Best practices

Use an isolated cache directory for tests. Keep database files and sensitive
history out of Git. Share configuration for cache placement, not the cache's user
data. Report missing backends as unavailable rather than successful maintenance.

## Related documentation

- [Fragment loading](FRAGMENT_LOADING_OPTIMIZATION.md)
- [Profile load-time optimization](PROFILE_LOAD_TIME_OPTIMIZATION.md)
- [Delivery and recovery](../../RELEASING.md)
