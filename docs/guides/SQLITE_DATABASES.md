# SQLite Databases Guide

This document describes the SQLite databases used in the PowerShell profile project for persistent data storage.

## Overview

The project uses SQLite databases stored in the `.cache/` directory (or custom location via `PS_PROFILE_CACHE_DIR`) for:

1. **Command History** - Persistent command execution tracking
2. **Performance Metrics** - Historical performance data
3. **Test Results Cache** - Test result caching for CI performance

All databases automatically fall back to in-memory or file-based storage if SQLite is not available.

## Database Locations

All databases are stored in the cache directory:

- `.cache/command-history.db` - Command execution history
- `.cache/performance-metrics.db` - Performance metrics
- `.cache/test-cache.db` - Test result cache

The cache directory is determined by:

1. `PS_PROFILE_CACHE_DIR` environment variable (if set)
2. Platform-specific cache directories:
   - Windows: `%LOCALAPPDATA%\PowerShellProfile`
   - Linux/macOS: `~/.cache/powershell-profile` or `$XDG_CACHE_HOME/powershell-profile`

## Command History Database

### Purpose

Tracks command execution history across PowerShell sessions, enabling:

- Persistent command history
- Usage analytics and statistics
- Command performance tracking
- Search and query capabilities

### Usage

```powershell
# Import the module
Import-Module scripts\lib\database\CommandHistoryDatabase.psm1

# Commands are automatically recorded when using performance insights
# (diagnostics-performance.ps1 fragment)

# Query command history
Get-CommandHistory -Limit 50
Get-CommandHistory -Since (Get-Date).AddDays(-7) -CommandPattern "git"

# Get usage statistics
Get-CommandUsageStats -Limit 20

# Clear old history
Clear-CommandHistory -OlderThan (Get-Date).AddMonths(-6)
```

### Schema

```sql
CREATE TABLE command_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    command_line TEXT NOT NULL,
    execution_time REAL,
    exit_code INTEGER,
    start_time INTEGER NOT NULL,
    end_time INTEGER,
    session_id TEXT,
    working_directory TEXT,
    created_at INTEGER NOT NULL
);
```

## Performance Metrics Database

### Purpose

Stores performance metrics for historical analysis:

- Startup benchmarks
- Test execution times
- Function performance
- Memory and CPU usage

### Usage

```powershell
# Import the module
Import-Module scripts\lib\database\PerformanceMetricsDatabase.psm1

# Record a metric
Add-PerformanceMetric -MetricType 'startup' -MetricName 'profile_load' -Value 1234.5 -Unit 'ms' -Environment 'local'

# Query metrics
Get-PerformanceMetrics -MetricType 'startup' -MetricName 'profile_load' -Since (Get-Date).AddDays(-30)

# Get aggregated statistics
Get-PerformanceStatistics -MetricType 'startup' -MetricName 'profile_load' -GroupBy 'day'

# Clear old metrics
Clear-PerformanceMetrics -OlderThan (Get-Date).AddMonths(-12)
```

### Schema

```sql
CREATE TABLE performance_metrics (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    metric_type TEXT NOT NULL,
    metric_name TEXT NOT NULL,
    value REAL NOT NULL,
    unit TEXT,
    test_suite TEXT,
    environment TEXT,
    timestamp INTEGER NOT NULL,
    metadata TEXT,
    created_at INTEGER NOT NULL
);
```

### Integration

Performance metrics are automatically recorded by:

- `Measure-Operation` function (scripts/lib/performance/PerformanceMeasurement.psm1)
- `benchmark-startup.ps1` script
- Test performance monitoring

## Test Cache Database

### Purpose

Caches test results to avoid re-running unchanged tests:

- File hash-based cache invalidation
- Test execution history
- Faster CI/CD runs

### Usage

```powershell
# Import the module
Import-Module scripts\lib\database\TestCacheDatabase.psm1

# Get cached test results
$cached = Get-TestCache -TestFilePath 'tests\unit\test.tests.ps1'
if ($cached -and $cached.IsValid) {
    # Use cached results
}

# Save test results
Save-TestCache -TestFilePath 'tests\unit\test.tests.ps1' -TestResult $pesterResult -ExecutionTime 5.2 -PassedCount 10 -FailedCount 0 -SkippedCount 2

# Get execution history
Get-TestExecutionHistory -TestFilePath 'tests\unit\test.tests.ps1' -Since (Get-Date).AddDays(-7)

# Clear cache
Clear-TestCache -OlderThan (Get-Date).AddMonths(-3)
```

### Schema

```sql
CREATE TABLE test_cache (
    test_file_path TEXT PRIMARY KEY,
    file_hash TEXT NOT NULL,
    last_write_time_ticks INTEGER NOT NULL,
    test_result TEXT NOT NULL,
    execution_time REAL,
    passed_count INTEGER,
    failed_count INTEGER,
    skipped_count INTEGER,
    cached_at INTEGER NOT NULL,
    updated_at INTEGER NOT NULL
);

CREATE TABLE test_execution_history (
    id INTEGER PRIMARY KEY AUTOINCREMENT,
    test_file_path TEXT NOT NULL,
    execution_time REAL,
    passed_count INTEGER,
    failed_count INTEGER,
    skipped_count INTEGER,
    timestamp INTEGER NOT NULL
);
```

### Integration

The test cache is automatically used by:

- `TestCache.psm1` module (scripts/utils/code-quality/modules/)
- Test runner scripts

## Migration from JSON/CSV

To migrate existing performance data from JSON/CSV files to SQLite:

```powershell
# Migrate baseline and benchmark data
pwsh -NoProfile -File scripts\utils\database\migrate-metrics-to-sqlite.ps1 `
    -BaselineFile scripts\data\performance-baseline.json `
    -BenchmarkFile scripts\data\startup-benchmark.csv

# Migrate metrics history snapshots
pwsh -NoProfile -File scripts\utils\database\migrate-metrics-to-sqlite.ps1 `
    -MetricsHistoryPath scripts\data\history
```

## Requirements

SQLite databases require the `sqlite3` command-line tool:

- **Windows**: `choco install sqlite -y` or `scoop install sqlite`
- **Linux**: `apt-get install sqlite3` or `yum install sqlite`
- **macOS**: `brew install sqlite`

If SQLite is not available, the modules gracefully fall back to:

- In-memory storage (Command History, Performance Metrics)
- JSON file storage (Test Cache)

## Corruption Handling

All databases include automatic corruption detection and recovery:

### Automatic Features

- **Integrity Checks**: Databases are checked for corruption before and after operations
- **Automatic Repair**: Corrupted databases are automatically repaired using VACUUM and dump/restore
- **Backup Before Repair**: Backups are created before repair attempts
- **Safe Operations**: All write operations are wrapped with corruption handling

### Manual Operations

```powershell
# Import SQLite utilities
Import-Module scripts\lib\utilities\SqliteDatabase.psm1

# Check database integrity
Test-DatabaseIntegrity -DatabasePath .cache\command-history.db

# Create backup
Backup-Database -DatabasePath .cache\command-history.db

# Repair corrupted database
Repair-Database -DatabasePath .cache\command-history.db -BackupBeforeRepair

# Safe operation wrapper (used automatically)
Invoke-DatabaseOperationSafely -DatabasePath .cache\command-history.db -ScriptBlock {
    # Your database operation here
}
```

### Corruption Recovery Process

1. **Detection**: Integrity check (PRAGMA integrity_check) detects corruption
2. **Backup**: Creates backup of corrupted database
3. **Repair Attempt 1**: Tries dump/restore method (most reliable)
4. **Repair Attempt 2**: Falls back to VACUUM if dump/restore fails
5. **Verification**: Verifies integrity after repair
6. **Retry**: Retries the original operation if repair succeeded

If repair fails, the database is removed and recreated on next initialization.

## Validation

Validate your database setup and configuration:

```powershell
# Basic validation
pwsh -NoProfile -File scripts\utils\database\validate-databases.ps1

# Full validation with operation testing
pwsh -NoProfile -File scripts\utils\database\validate-databases.ps1 -TestOperations

# Using task
task db-validate
task db-validate-full
```

The validation script checks:

- SQLite availability
- Cache directory accessibility
- Database initialization
- Database integrity
- Basic read/write operations (if `-TestOperations` is used)

## Troubleshooting

### Database not initializing

Check if SQLite is available:

```powershell
Test-SqliteAvailable
Get-SqliteCommandName
```

### Database locked errors

SQLite uses WAL (Write-Ahead Logging) mode for better concurrency. If you encounter locking issues:

1. Ensure only one process is writing to the database
2. Check for stale lock files in the cache directory
3. Restart PowerShell sessions

### Database corruption

If you encounter corruption errors:

1. Check integrity: `Test-DatabaseIntegrity -DatabasePath .cache\command-history.db`
2. Repair: `Repair-Database -DatabasePath .cache\command-history.db -BackupBeforeRepair`
3. If repair fails, remove the database file and it will be recreated

### Clear all databases

```powershell
# Command History
Clear-CommandHistory

# Performance Metrics
Clear-PerformanceMetrics

# Test Cache
Clear-TestCache
```

## Performance Considerations

- **WAL Mode**: All databases use WAL mode for better concurrent access
- **Indexes**: Appropriate indexes are created for common query patterns
- **Automatic Cleanup**: Consider periodic cleanup of old data to maintain performance
- **Cache Size**: SQLite databases are typically small (< 10MB) but can grow with extensive history

## Database Maintenance

### Health Checks

Check the health of all databases:

```powershell
# Using the maintenance script
pwsh -NoProfile -File scripts\utils\database\database-maintenance.ps1 -Action health

# Or using the function directly
Import-Module scripts\lib\utilities\SqliteDatabase.psm1
Test-DatabaseHealth
```

### Database Statistics

Get detailed statistics for databases:

```powershell
# All databases
pwsh -NoProfile -File scripts\utils\database\database-maintenance.ps1 -Action statistics

# Specific database
pwsh -NoProfile -File scripts\utils\database\database-maintenance.ps1 -Action statistics -Database "command-history"

# Using function directly
Import-Module scripts\lib\utilities\SqliteDatabase.psm1
Get-DatabaseStatistics -DatabasePath .cache\command-history.db
```

### Optimization

Optimize databases to reclaim space and update statistics:

```powershell
# All databases
pwsh -NoProfile -File scripts\utils\database\database-maintenance.ps1 -Action optimize

# Specific database
pwsh -NoProfile -File scripts\utils\database\database-maintenance.ps1 -Action optimize -Database "performance-metrics"

# Using function directly
Import-Module scripts\lib\utilities\SqliteDatabase.psm1
Optimize-Database -DatabasePath .cache\performance-metrics.db
```

### Backup

Create backups of databases:

```powershell
# All databases
pwsh -NoProfile -File scripts\utils\database\database-maintenance.ps1 -Action backup

# Specific database
pwsh -NoProfile -File scripts\utils\database\database-maintenance.ps1 -Action backup -Database "test-cache"

# Using function directly
Import-Module scripts\lib\utilities\SqliteDatabase.psm1
Backup-Database -DatabasePath .cache\test-cache.db
```

### Repair

Repair corrupted databases:

```powershell
# All databases
pwsh -NoProfile -File scripts\utils\database\database-maintenance.ps1 -Action repair

# Specific database
pwsh -NoProfile -File scripts\utils\database\database-maintenance.ps1 -Action repair -Database "command-history"

# Using function directly
Import-Module scripts\lib\utilities\SqliteDatabase.psm1
Repair-Database -DatabasePath .cache\command-history.db -BackupBeforeRepair
```

## Best Practices

1. **Regular Cleanup**: Periodically clear old data to maintain performance
2. **Regular Health Checks**: Run health checks periodically to catch issues early
3. **Regular Optimization**: Optimize databases monthly to maintain performance
4. **Backup**: Consider backing up `.cache/` directory for important metrics
5. **Environment Variables**: Use `PS_PROFILE_CACHE_DIR` for project-local cache directories
6. **Monitoring**: Use `Get-PerformanceStatistics` to monitor database growth

## Related Documentation

- [Fragment Loading Optimization](FRAGMENT_LOADING_OPTIMIZATION.md) - Fragment cache details
- [Performance Analysis](PROFILE_LOADING_PERFORMANCE_ANALYSIS.md) - Performance tracking
- [Development Guide](DEVELOPMENT.md) - Test runner and CI/CD
