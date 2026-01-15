# FragmentCache Module Refactoring

## Overview

The `FragmentCache.psm1` module (2328 lines) has been identified as monolithic and is being refactored into smaller, more maintainable modules following existing patterns in the codebase.

## Refactoring Plan

### Completed

1. **FragmentCachePath.psm1** - Created
   - `Get-FragmentCacheDbPath` - Path resolution and cache directory management
   - Handles cross-platform path resolution
   - Manages cache directory creation

### In Progress

2. **FragmentCacheContent.psm1** - To be created

   - `Get-FragmentContentCache` - Retrieve cached content from SQLite
   - `Set-FragmentContentCache` - Store cached content to SQLite
   - `Get-FragmentContentCacheBatch` - Batch retrieval for performance

3. **FragmentCacheAst.psm1** - To be created

   - `Get-FragmentAstCache` - Retrieve cached AST functions from SQLite
   - `Set-FragmentAstCache` - Store cached AST functions to SQLite
   - `Get-FragmentAstCacheBatch` - Batch retrieval for performance

4. **FragmentCacheStats.psm1** - To be created
   - `Get-FragmentCacheStats` - Get cache statistics
   - `Clear-FragmentCacheDb` - Clear cache entries

### Remaining Work

5. **FragmentCache.psm1** - Update to thin orchestrator
   - Keep `Initialize-FragmentCache` (main initialization)
   - Keep wrapper functions for SQLite module delegation (`Test-SqliteAvailable`, `Get-SqliteCommandName`, `Initialize-FragmentCacheDb`)
   - Import sub-modules: FragmentCachePath, FragmentCacheContent, FragmentCacheAst, FragmentCacheStats
   - Export all functions for backward compatibility

## Module Dependencies

```
FragmentCache.psm1 (orchestrator)
├── FragmentCacheSqlite.psm1 (already exists)
│   ├── Test-SqliteAvailable
│   ├── Get-SqliteCommandName
│   └── Initialize-FragmentCacheDb
├── FragmentCachePath.psm1 (created)
│   └── Get-FragmentCacheDbPath
├── FragmentCacheContent.psm1 (to create)
│   ├── Get-FragmentContentCache
│   ├── Set-FragmentContentCache
│   └── Get-FragmentContentCacheBatch
├── FragmentCacheAst.psm1 (to create)
│   ├── Get-FragmentAstCache
│   ├── Set-FragmentAstCache
│   └── Get-FragmentAstCacheBatch
└── FragmentCacheStats.psm1 (to create)
    ├── Get-FragmentCacheStats
    └── Clear-FragmentCacheDb
```

## Implementation Notes

### Module Loading Pattern

Modules should be loaded using `Import-Module` at the top of `FragmentCache.psm1`:

```powershell
# Load sub-modules
$moduleDir = $PSScriptRoot
Import-Module (Join-Path $moduleDir 'FragmentCachePath.psm1') -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module (Join-Path $moduleDir 'FragmentCacheContent.psm1') -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module (Join-Path $moduleDir 'FragmentCacheAst.psm1') -DisableNameChecking -ErrorAction SilentlyContinue
Import-Module (Join-Path $moduleDir 'FragmentCacheStats.psm1') -DisableNameChecking -ErrorAction SilentlyContinue
```

### Function Dependencies

- Content/AST cache functions depend on:

  - `Initialize-FragmentCacheDb` (from FragmentCacheSqlite)
  - `Get-FragmentCacheDbPath` (from FragmentCachePath)
  - `Get-SqliteCommandName` (from FragmentCacheSqlite)

- Stats functions depend on:
  - `Test-SqliteAvailable` (from FragmentCacheSqlite)
  - `Get-FragmentCacheDbPath` (from FragmentCachePath)
  - `Get-SqliteCommandName` (from FragmentCacheSqlite)

### Export Strategy

`FragmentCache.psm1` should export all functions for backward compatibility:

```powershell
Export-ModuleMember -Function @(
    'Initialize-FragmentCache',
    'Get-FragmentCacheDbPath',
    'Test-SqliteAvailable',
    'Get-SqliteCommandName',
    'Initialize-FragmentCacheDb',
    'Get-FragmentContentCache',
    'Set-FragmentContentCache',
    'Get-FragmentContentCacheBatch',
    'Get-FragmentAstCache',
    'Set-FragmentAstCache',
    'Get-FragmentAstCacheBatch',
    'Get-FragmentCacheStats',
    'Clear-FragmentCacheDb'
)
```

## Benefits

1. **Reduced Complexity**: Main file reduced from 2328 lines to ~200-300 lines
2. **Better Organization**: Related functionality grouped in focused modules
3. **Easier Maintenance**: Smaller files are easier to understand and modify
4. **Improved Testability**: Modules can be tested independently
5. **Clear Separation of Concerns**: Each module has a single, well-defined responsibility

## Testing

After refactoring, ensure:

1. All existing tests pass
2. Module loading works correctly
3. Function exports are preserved
4. Performance is maintained (or improved)
5. Error handling works as expected

## References

- See `ARCHITECTURE.md` for examples of similar refactorings (23-starship.ps1, 07-system.ps1, etc.)
- Follow patterns established in `FragmentCacheSqlite.psm1` for module structure
- Maintain backward compatibility with existing callers
