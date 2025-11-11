# Function Naming Exceptions

This document lists intentional exceptions to PowerShell naming conventions in the codebase.

## Overview

While most functions follow PowerShell's approved verb naming conventions, some exceptions are intentional for:

- Bootstrap functions that define the infrastructure itself
- Lazy-loading helper functions
- Common utility patterns
- Test functions
- Short convenience aliases

## Exception Categories

### Bootstrap Functions (00-bootstrap.ps1)

These functions define the infrastructure and cannot use `Set-AgentModeFunction` themselves:

- `Set-AgentModeFunction` - Defines the collision-safe function registration mechanism
- `Set-AgentModeAlias` - Defines the collision-safe alias registration mechanism
- `Test-CachedCommand` - Cached command testing utility
- `Test-IsWindows`, `Test-IsLinux`, `Test-IsMacOS` - Platform detection helpers
- `Get-UserHome` - Cross-platform home directory helper
- `Register-LazyFunction` - Lazy-loading registration helper
- `Register-DeprecatedFunction` - Deprecation management helper
- `Get-FragmentConfigPath`, `Get-FragmentConfig`, `Save-FragmentConfig` - Fragment configuration helpers
- `ConvertTo-Hashtable` - Configuration conversion helper
- `Test-ProfileFragmentEnabled`, `Enable-ProfileFragment`, `Disable-ProfileFragment`, `Get-ProfileFragment` - Fragment management
- `Get-FragmentDependencies`, `Test-FragmentDependencies`, `Get-FragmentLoadOrder` - Dependency management
- `Visit-Fragment` - Internal helper for topological sort (not exported)

**Reason**: These are foundational functions that must be defined directly to enable the collision-safe registration pattern for other functions.

### Lazy-Loading Helper Functions

These functions use the `Ensure-` prefix to indicate lazy initialization:

- `Ensure-FileConversion` - Lazy-loads file conversion utilities
- `Ensure-FileListing` - Lazy-loads file listing utilities
- `Ensure-FileNavigation` - Lazy-loads file navigation utilities
- `Ensure-FileUtilities` - Lazy-loads file utility functions
- `Ensure-GitHelper` - Lazy-loads git helper functions

**Reason**: The `Ensure-` prefix is a common pattern for lazy-loading initialization functions. These are internal helpers that initialize other functions on first use.

### Common Utility Patterns

Functions that use common, widely-understood verbs that aren't in the approved list:

- `Reload-Profile` - Reloads the PowerShell profile
- `Continue-GitRebase` - Continues a git rebase operation
- `Jump-Directory`, `Jump-DirectoryQuick` - Quick directory navigation (common pattern)
- `Time-Command` - Utility script for timing command execution

**Reason**: These verbs (`Reload`, `Continue`, `Jump`, `Time`) are widely used and understood in the PowerShell community, even if not officially approved.

### Short Convenience Functions

Functions with intentionally short names for quick access:

- `am-list` - Lists agent mode functions
- `am-doc` - Shows agent mode documentation

**Reason**: These are convenience aliases with short names for quick access. The `am-` prefix indicates they're part of the agent mode system.

### Test Functions

Functions used only in test files:

- `Simple-Function` - Test helper function

**Reason**: Test functions don't need to follow production naming conventions.

## Functions Not Using Set-AgentModeFunction

Many functions in `profile.d` files use direct `function` definitions instead of `Set-AgentModeFunction`. This is intentional for:

1. **Bootstrap functions** (see above) - Must be defined directly
2. **Lazy-loading stubs** - Functions that initialize on first call (detected by checking for `Ensure-*` calls)
3. **Performance-critical functions** - Direct definition avoids overhead
4. **Legacy functions** - Older functions that predate the collision-safe pattern

**Note**: While new functions should use `Set-AgentModeFunction` for collision-safe registration, existing legacy functions are acceptable as-is. The validation script will flag these for awareness, but they don't need to be changed unless being actively refactored.

### Lazy-Loading Pattern

Some functions use a lazy-loading pattern where they check for the actual function and initialize it if needed:

```powershell
function Get-FileHead {
    if (-not (Test-Path Function:\Get-FileHead)) {
        Ensure-FileUtilities
    }
    return & (Get-Item Function:\Get-FileHead -ErrorAction SilentlyContinue).ScriptBlock.InvokeReturnAsIs($args)
}
```

This pattern allows expensive initialization to be deferred until the function is actually used.

## Recommendations

1. **New functions** should use `Set-AgentModeFunction` for collision-safe registration
2. **New lazy-loading helpers** may use `Ensure-` prefix (documented exception)
3. **Bootstrap functions** must be defined directly (cannot use `Set-AgentModeFunction`)
4. **Test functions** may use any naming convention

## Validation

Run the validation script to check for naming issues:

```powershell
pwsh -NoProfile -File scripts\utils\code-quality\validate-function-naming.ps1
```

The script will automatically exclude documented exceptions from its report.
