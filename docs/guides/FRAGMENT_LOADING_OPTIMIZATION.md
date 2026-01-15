# Fragment Loading Optimization

## Current Issue

**Problem**: Fragment loading takes a long time because all fragments are loaded upfront, even though there's an on-demand command loading system.

**Root Cause**: Commands are only registered in the `FragmentCommandRegistry` when fragments are **loaded** (via `Set-AgentModeFunction`/`Set-AgentModeAlias`). This creates a chicken-and-egg problem:

1. For `CommandDispatcher` to work, commands must be in the registry
2. For commands to be in the registry, fragments must be loaded
3. So the profile loads all fragments to populate the registry
4. This defeats the purpose of on-demand loading

## Current Flow

```
Profile Start
  ↓
Load Bootstrap Fragments
  ↓
Load ALL Fragments (to populate registry)
  ├─ Set-AgentModeFunction registers functions
  ├─ Set-AgentModeAlias registers aliases
  └─ Commands now available in registry
  ↓
Register CommandDispatcher
  ↓
Commands can now be loaded on-demand (but fragments are already loaded!)
```

## Proposed Solution: AST-Based Pre-Registration

Parse fragments using AST (without executing them) to extract command names and populate the registry **before** loading fragments.

### Implementation Approach

1. **Add AST-based command discovery** to `FragmentCommandRegistry.psm1`:

   - `Register-CommandsFromFragmentAst` - Parses a fragment file and registers all commands found
   - Uses existing `AstParsing.psm1` module to extract:
     - Function definitions (`function Name { ... }`)
     - `Set-AgentModeFunction` calls
     - `Set-AgentModeAlias` calls
     - Direct function assignments (`Set-Item Function:global:Name`)

2. **Modify profile loading** to pre-register commands:

   ```
   Profile Start
     ↓
   Load Bootstrap Fragments (required for AST parsing)
     ↓
   Parse ALL Fragments (AST only, no execution)
     ├─ Extract command names
     └─ Register commands in registry
     ↓
   Register CommandDispatcher (now has full registry)
     ↓
   Load fragments on-demand when commands are called
   ```

3. **Benefits**:
   - **Faster startup**: Only bootstrap fragments load initially
   - **True lazy loading**: Fragments load only when their commands are used
   - **Registry populated**: CommandDispatcher can find all commands immediately
   - **Backward compatible**: Existing registration during load still works (as fallback)

### Implementation Details

#### Step 1: Add Command Discovery Function

Add to `scripts/lib/fragment/FragmentCommandRegistry.psm1`:

```powershell
function Register-CommandsFromFragmentAst {
    [CmdletBinding()]
    [OutputType([int])]
    param(
        [Parameter(Mandatory)]
        [string]$FragmentPath,

        [Parameter(Mandatory)]
        [string]$FragmentName
    )

    $registeredCount = 0

    try {
        # Use AstParsing module if available
        if (Get-Command Get-PowerShellAst -ErrorAction SilentlyContinue) {
            $ast = Get-PowerShellAst -Path $FragmentPath
            $functions = Get-FunctionsFromAst -Ast $ast

            # Register function definitions
            foreach ($func in $functions) {
                if ($func.Name -and $func.Name -notmatch '^global:') {
                    $null = Register-FragmentCommand -CommandName $func.Name -FragmentName $FragmentName -CommandType 'Function'
                    $registeredCount++
                }
            }
        }

        # Also parse for Set-AgentModeFunction/Set-AgentModeAlias calls
        $content = Get-Content -Path $FragmentPath -Raw -ErrorAction SilentlyContinue
        if ($content) {
            # Match Set-AgentModeFunction -Name 'CommandName'
            $functionMatches = [regex]::Matches($content, "Set-AgentModeFunction\s+-Name\s+['""]([A-Za-z0-9_\-]+)['""]")
            foreach ($match in $functionMatches) {
                $cmdName = $match.Groups[1].Value
                if (-not (Test-CommandInRegistry -CommandName $cmdName)) {
                    $null = Register-FragmentCommand -CommandName $cmdName -FragmentName $FragmentName -CommandType 'Function'
                    $registeredCount++
                }
            }

            # Match Set-AgentModeAlias -Name 'AliasName'
            $aliasMatches = [regex]::Matches($content, "Set-AgentModeAlias\s+-Name\s+['""]([A-Za-z0-9_\-]+)['""]")
            foreach ($match in $aliasMatches) {
                $aliasName = $match.Groups[1].Value
                if (-not (Test-CommandInRegistry -CommandName $aliasName)) {
                    $null = Register-FragmentCommand -CommandName $aliasName -FragmentName $FragmentName -CommandType 'Alias'
                    $registeredCount++
                }
            }
        }
    }
    catch {
        if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
            Write-StructuredWarning -Message "Failed to parse fragment for commands: $FragmentPath" -OperationName 'fragment-registry.pre-register' -Context @{
                fragment_path = $FragmentPath
                fragment_name = $FragmentName
            } -Code 'AstParseFailed'
        }
    }

    return $registeredCount
}
```

#### Step 2: Add Batch Pre-Registration

Add to `scripts/lib/fragment/FragmentCommandRegistry.psm1`:

```powershell
function Register-AllFragmentCommands {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [Parameter(Mandatory)]
        [System.IO.FileInfo[]]$FragmentFiles
    )

    $stats = @{
        TotalFragments = $FragmentFiles.Count
        RegisteredCommands = 0
        FailedFragments = 0
    }

    foreach ($fragment in $FragmentFiles) {
        $fragmentName = $fragment.BaseName
        try {
            $count = Register-CommandsFromFragmentAst -FragmentPath $fragment.FullName -FragmentName $fragmentName
            $stats.RegisteredCommands += $count
        }
        catch {
            $stats.FailedFragments++
            if (Get-Command Write-StructuredWarning -ErrorAction SilentlyContinue) {
                Write-StructuredWarning -Message "Failed to pre-register commands from fragment: $fragmentName" -OperationName 'fragment-registry.pre-register-all' -Context @{
                    fragment_name = $fragmentName
                    fragment_path = $fragment.FullName
                } -Code 'PreRegisterFailed'
            }
        }
    }

    return $stats
}
```

#### Step 3: Modify Profile Loading

Modify `scripts/lib/profile/ProfileFragmentLoader.psm1` to call pre-registration before loading fragments:

```powershell
# After bootstrap is loaded, but before loading other fragments:
if (Get-Command Register-AllFragmentCommands -ErrorAction SilentlyContinue) {
    $preRegisterStats = Register-AllFragmentCommands -FragmentFiles $FragmentsToLoad
    if ($env:PS_PROFILE_DEBUG) {
        Write-Verbose "Pre-registered $($preRegisterStats.RegisteredCommands) commands from $($preRegisterStats.TotalFragments) fragments"
    }
}

# Now CommandDispatcher can work even if fragments aren't loaded yet
# Fragments will load on-demand when commands are called
```

## Configuration

Environment variables to control behavior:

- `PS_PROFILE_PRE_REGISTER_COMMANDS` - Enable/disable command pre-registration (default: `true`)

  - Set to `0` or `false` to disable pre-registration
  - Pre-registration must be enabled for lazy loading to work
  - When enabled, fragments are parsed (without execution) to discover commands before loading

- `PS_PROFILE_LAZY_LOAD_FRAGMENTS` - Enable/disable lazy loading (default: `true`)

  - Set to `1` or `true` to skip fragment loading (fragments load on-demand)
  - Set to `0` or `false` to load all fragments during profile initialization
  - When enabled, only bootstrap fragments load; other fragments load when commands are called
  - Pre-registration is automatically skipped if lazy loading is disabled (fragments will register commands when loaded)

- `PS_PROFILE_LOAD_ALL_FRAGMENTS` - Inverse control for lazy loading

  - Set to `0` or `false` to enable lazy loading (skip fragment loading)
  - Set to `1` or `true` to load all fragments (disable lazy loading)

- `PS_PROFILE_CREATE_PROXIES` - Enable/disable proxy function creation for autocomplete (default: `true`)

  - Set to `1` or `true` to create proxy functions (enables tab completion, default)
  - Set to `0` or `false` to skip proxy creation (faster startup, but tab completion may not work)
  - Proxy functions are lightweight stubs that load fragments on-demand
  - Proxy creation is deferred until after bootstrap is fully loaded to ensure all required functions are available
  - Disable if you don't need tab completion and want faster startup

**Note**: `PS_PROFILE_LAZY_LOAD_FRAGMENTS` takes precedence over `PS_PROFILE_LOAD_ALL_FRAGMENTS` if both are set.

## Implementation Status

✅ **Phase 1**: Command pre-registration - **COMPLETE**

- Commands are pre-registered from fragment parsing using both AST and regex parsing
- Works alongside existing registration during fragment loading
- **Always uses dual parsing** (AST + regex) for complete command coverage:
  - AST finds function definitions (`function Name { ... }`)
  - Regex finds `Set-AgentModeFunction`, `Set-AgentModeAlias`, and `Set-Item Function:...` patterns
  - Both results are cached separately and combined when loading from cache
- File changes automatically trigger re-parsing with both modes and cache updates

✅ **Phase 2**: Lazy loading - **COMPLETE**

- `PS_PROFILE_LAZY_LOAD_FRAGMENTS` environment variable added
- Fragments skip loading when lazy loading is enabled
- Commands load on-demand via CommandDispatcher

✅ **Phase 3**: Default behavior - **COMPLETE**

- Lazy loading is now the **default** behavior
- Set `PS_PROFILE_LOAD_ALL_FRAGMENTS=1` to load all fragments (old behavior)

## Performance Impact

**Expected improvements**:

- **Startup time**: 50-80% reduction (only bootstrap fragments load)
- **Memory usage**: Lower initial footprint (fragments load on-demand)
- **First command call**: Slight delay (fragment loads on first use)
- **Subsequent calls**: No difference (fragment already loaded)

## Limitations

1. **Dynamic commands**: Commands created at runtime (not in AST) won't be pre-registered

   - Solution: Fallback to loading fragment if command not found

2. **Complex command creation**: Commands created via string manipulation may not be detected

   - Solution: Use regex patterns to catch common patterns

3. **Dependencies**: Fragment dependencies must still be resolved
   - Solution: Load dependencies when fragment is loaded on-demand

## Testing

1. Verify all commands are discoverable via AST parsing
2. Test on-demand loading works correctly
3. Validate backward compatibility (existing registration still works)
4. Performance benchmarks (startup time, first command call time)

## Related Documentation

- [FRAGMENT_COMMAND_ACCESS.md](./FRAGMENT_COMMAND_ACCESS.md) - Command access system
- [ARCHITECTURE.md](../../ARCHITECTURE.md) - Profile architecture
- `scripts/lib/code-analysis/AstParsing.psm1` - AST parsing utilities
