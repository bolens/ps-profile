# Fragment Numbering Migration Plan

## Executive Summary

**Recommendation: Yes, remove numbering from fragments for better scalability**

The current numbered prefix system (00-99) becomes unwieldy as we add 38+ new modules. The profile loader already has a robust dependency resolution system that can handle explicit dependencies, making numeric prefixes unnecessary.

## Current State

### Current System

- **Numbered prefixes**: `00-bootstrap.ps1`, `01-env.ps1`, `11-git.ps1`, etc.
- **Load order**: Determined by numeric prefix (00-99)
- **Dependency system**: Already exists but underutilized
- **Tier grouping**: Based on numeric ranges (00-09, 10-29, 30-69, 70-99)

### Existing Dependency Infrastructure

The profile loader already supports:

1. **Explicit dependencies** via comments:

   ```powershell
   #Requires -Fragment 'bootstrap'
   #Requires -Fragment 'env'
   # Or: # Dependencies: bootstrap, env
   ```

2. **Topological sorting** (`Get-FragmentLoadOrder`) - automatically resolves dependencies

3. **Dependency validation** (`Test-FragmentDependencies`) - detects missing/circular dependencies

4. **Tier-based loading** (`Get-FragmentTiers`) - currently uses numeric prefixes but could use explicit tier declarations

## Problems with Numbered Approach

1. **Scalability**: With 38+ new modules planned, we'd exceed 99 easily
2. **Maintenance**: Adding/removing fragments requires renumbering
3. **Merge conflicts**: Multiple developers working on fragments cause numbering conflicts
4. **Gaps**: Removing a fragment leaves gaps (e.g., 15-shortcuts.ps1 removed, gap at 15)
5. **Unclear dependencies**: Numbers don't express actual dependencies
6. **Tier ambiguity**: What tier should a new fragment belong to?

## Proposed Solution

### Phase 1: Named Fragments with Explicit Dependencies

**Naming Convention:**

- Remove numeric prefixes
- Use descriptive names: `bootstrap.ps1`, `env.ps1`, `git.ps1`, `aws.ps1`
- Keep names short but descriptive

**Dependency Declaration:**

```powershell
# ===============================================
# git.ps1
# Git helpers and aliases
# ===============================================
# Dependencies: bootstrap, env
# Tier: core
```

**Benefits:**

- No numbering conflicts
- Clear dependencies
- Easy to add/remove fragments
- Self-documenting

### Phase 2: Explicit Tier Declarations

Replace numeric-based tier grouping with explicit tier declarations:

```powershell
# Tier: core        # Critical bootstrap (must load first)
# Tier: essential   # Core functionality (env, files, utilities)
# Tier: standard    # Common tools (git, containers, cloud)
# Tier: optional     # Advanced features (monitoring, diagnostics)
```

**Tier Definitions:**

- **core**: Bootstrap and critical initialization (currently 00-09)
- **essential**: Core functionality needed by most workflows (env, files, utilities)
- **standard**: Standard development tools (git, containers, cloud, languages)
- **optional**: Advanced/optional features (monitoring, diagnostics, specialized tools)

### Phase 3: Enhanced Dependency System

Add support for:

- **Optional dependencies**: `# Dependencies: bootstrap, env (optional: starship)`
- **Tier hints**: `# Tier: standard` for batch optimization
- **Load priority**: `# Priority: high` for fragments that should load early within their tier

## Migration Strategy

### Step 1: Update Fragment Loading Logic

**File**: `scripts/lib/fragment/FragmentLoading.psm1`

**Changes needed:**

1. Update `Get-FragmentTiers` to use explicit tier declarations instead of numeric prefixes
2. Add `Get-FragmentTier` function to parse tier from fragment header
3. Fallback to alphabetical sorting if no dependencies/tiers declared

**New function:**

```powershell
function Get-FragmentTier {
    param([System.IO.FileInfo]$FragmentFile)

    # Parse # Tier: tier-name from header
    # Default to 'optional' if not specified
    # Return: 'core', 'essential', 'standard', or 'optional'
}
```

### Step 2: Update Profile Loader

**File**: `Microsoft.PowerShell_profile.ps1`

**Changes needed:**

1. Remove numeric prefix matching logic
2. Use dependency-aware loading as primary method
3. Update tier grouping to use explicit tier declarations
4. Keep bootstrap special-case (always loads first)

**Key changes:**

```powershell
# OLD: if ($fragment.BaseName -match '^0[1-9]-')
# NEW: if (Get-FragmentTier -FragmentFile $fragment -eq 'core')

# OLD: Sort-Object Name (relies on numeric prefix)
# NEW: Get-FragmentLoadOrder -FragmentFiles $fragments (dependency-aware)
```

### Step 3: Migrate Existing Fragments

**Migration script approach:**

1. Create migration script that:
   - Renames files (removes numeric prefix)
   - Adds dependency declarations based on current load order
   - Adds tier declarations based on current numeric ranges
   - Preserves all content

**Example migration:**

```
00-bootstrap.ps1 → bootstrap.ps1
  # Tier: core

01-env.ps1 → env.ps1
  # Dependencies: bootstrap
  # Tier: essential

11-git.ps1 → git.ps1
  # Dependencies: bootstrap, env
  # Tier: standard
```

### Step 4: Update Documentation

**Files to update:**

- `ARCHITECTURE.md` - Update fragment loading documentation
- `PROFILE_README.md` - Update fragment structure documentation
- `AGENTS.md` - Update fragment development guidelines
- `CONTRIBUTING.md` - Update contribution guidelines

### Step 5: Backward Compatibility

**Transition period:**

- Support both numbered and named fragments during migration
- Detect fragment naming style and handle appropriately
- Log warnings for numbered fragments (deprecation notice)

**Detection logic:**

```powershell
if ($fragment.BaseName -match '^\d+-') {
    # Legacy numbered fragment
    Write-Warning "Fragment '$($fragment.Name)' uses legacy numbering. Consider migrating to named fragment with explicit dependencies."
    # Extract tier from numeric prefix for compatibility
}
```

## Implementation Plan

### Phase 1: Foundation (Week 1)

- [ ] Update `Get-FragmentTiers` to support explicit tier declarations
- [ ] Add `Get-FragmentTier` function
- [ ] Update profile loader to use dependency-aware loading as primary
- [ ] Add backward compatibility for numbered fragments

### Phase 2: Migration (Week 2)

- [ ] Create migration script
- [ ] Migrate core fragments (00-09) first
- [ ] Migrate essential fragments (10-29)
- [ ] Migrate standard fragments (30-69)
- [ ] Migrate optional fragments (70-99)

### Phase 3: Cleanup (Week 3)

- [ ] Remove backward compatibility code
- [ ] Update all documentation
- [ ] Update tests
- [ ] Verify all fragments load correctly

### Phase 4: New Modules (Ongoing)

- [ ] All new modules use named fragments with explicit dependencies
- [ ] No numbering required
- [ ] Clear dependency declarations

## Example: Before and After

### Before (Numbered)

```
profile.d/
  00-bootstrap.ps1
  01-env.ps1
  02-files.ps1
  11-git.ps1
  22-containers.ps1
  31-aws.ps1
  76-security-tools.ps1  # New module - where does it go?
```

**Problems:**

- Where should 76-security-tools.ps1 go?
- What if we need more than 99 fragments?
- Dependencies not clear from numbers

### After (Named with Dependencies)

```
profile.d/
  bootstrap.ps1
    # Tier: core

  env.ps1
    # Dependencies: bootstrap
    # Tier: essential

  files.ps1
    # Dependencies: bootstrap, env
    # Tier: essential

  git.ps1
    # Dependencies: bootstrap, env
    # Tier: standard

  containers.ps1
    # Dependencies: bootstrap, env
    # Tier: standard

  aws.ps1
    # Dependencies: bootstrap, env
    # Tier: standard

  security-tools.ps1  # New module - clear!
    # Dependencies: bootstrap, env
    # Tier: standard
```

**Benefits:**

- Clear dependencies
- No numbering conflicts
- Easy to add anywhere
- Self-documenting

## Tier Guidelines

### Core Tier

- **Purpose**: Critical initialization that must load first
- **Examples**: `bootstrap.ps1`
- **Load order**: Always first, before any dependencies

### Essential Tier

- **Purpose**: Core functionality needed by most workflows
- **Examples**: `env.ps1`, `files.ps1`, `utilities.ps1`
- **Dependencies**: Usually depends on `bootstrap`, sometimes `env`

### Standard Tier

- **Purpose**: Standard development tools and integrations
- **Examples**: `git.ps1`, `containers.ps1`, `aws.ps1`, `security-tools.ps1`
- **Dependencies**: Usually depends on `bootstrap`, `env`, sometimes `utilities`

### Optional Tier

- **Purpose**: Advanced/optional features
- **Examples**: `performance-insights.ps1`, `system-monitor.ps1`
- **Dependencies**: May depend on multiple standard-tier fragments

## Dependency Best Practices

1. **Minimize dependencies**: Only declare what's actually needed
2. **Be explicit**: Don't rely on implicit ordering
3. **Group related**: Fragments in same category can share dependencies
4. **Avoid circular**: Use `Test-FragmentDependencies` to validate
5. **Document why**: Add comments explaining non-obvious dependencies

## Testing Strategy

1. **Unit tests**: Test dependency resolution with various dependency graphs
2. **Integration tests**: Verify fragments load in correct order
3. **Migration tests**: Verify migration script works correctly
4. **Backward compatibility tests**: Verify numbered fragments still work during transition

## Rollback Plan

If issues arise:

1. Keep numbered fragment support during transition period
2. Migration script creates backup of original files
3. Can revert by restoring numbered files
4. Gradual migration allows testing at each stage

## Benefits Summary

✅ **Scalability**: No limit on number of fragments
✅ **Maintainability**: Easy to add/remove fragments
✅ **Clarity**: Explicit dependencies are self-documenting
✅ **Flexibility**: No rigid numbering scheme
✅ **Collaboration**: No merge conflicts from numbering
✅ **Future-proof**: Works with any number of modules

## Next Steps

1. **Review and approve** this migration plan
2. **Create migration script** to automate fragment renaming
3. **Update fragment loading logic** to support explicit tiers
4. **Migrate fragments incrementally** (test after each batch)
5. **Update documentation** as migration progresses
6. **Remove backward compatibility** once migration complete

## Questions to Consider

1. **Naming convention**: Should we use kebab-case (`git-helpers.ps1`) or simple names (`git.ps1`)?
2. **Tier granularity**: Are 4 tiers enough, or should we add more?
3. **Migration timeline**: How long should backward compatibility last?
4. **New module naming**: Should new modules follow a specific pattern?

## Recommendation

**Proceed with migration** - The benefits outweigh the migration effort, and the infrastructure already exists to support it. The numbered approach served us well initially, but explicit dependencies are the right long-term solution for scalability.
