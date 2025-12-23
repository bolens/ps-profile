# Refactoring Opportunities

This document identifies refactoring opportunities that should be addressed during the module expansion and fragment numbering migration.

## Table of Contents

1. [High Priority Refactorings](#high-priority-refactorings)
2. [Medium Priority Refactorings](#medium-priority-refactorings)
3. [Low Priority Refactorings](#low-priority-refactorings)
4. [Implementation Strategy](#implementation-strategy)

---

## High Priority Refactorings

### 1. Standardize Tool Wrapper Pattern

**Problem**: The `modern-cli.ps1` module has repetitive code for each tool wrapper. Each tool follows the same pattern but is duplicated.

**Current Pattern** (repeated 8+ times):

```powershell
if (-not (Test-Path Function:bat -ErrorAction SilentlyContinue)) {
    Set-Item -Path Function:bat -Value {
        param([Parameter(ValueFromRemainingArguments = $true)] $a)
        if (Get-Command bat -CommandType Application -ErrorAction SilentlyContinue) {
            & (Get-Command bat -CommandType Application) @a
        } else {
            Write-Warning 'bat not found'
        }
    } -Force | Out-Null
}
```

**Proposed Solution**: Create a helper function in bootstrap:

```powershell
# In 00-bootstrap/FunctionRegistration.ps1 (or bootstrap.ps1 after migration)
function Register-ToolWrapper {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$FunctionName,

        [Parameter(Mandatory)]
        [string]$CommandName,

        [string]$WarningMessage = "$CommandName not found",

        [string]$InstallHint = $null
    )

    if (Test-Path Function:$FunctionName -ErrorAction SilentlyContinue) {
        return
    }

    $body = {
        param([Parameter(ValueFromRemainingArguments = $true)] $Arguments)

        if (Test-CachedCommand $CommandName) {
            & $CommandName @Arguments
        }
        else {
            if ($InstallHint) {
                Write-MissingToolWarning -Tool $CommandName -InstallHint $InstallHint
            }
            else {
                Write-Warning $WarningMessage
            }
        }
    }

    Set-AgentModeFunction -Name $FunctionName -Body $body
}
```

**Usage**:

```powershell
Register-ToolWrapper -FunctionName 'bat' -CommandName 'bat' -InstallHint 'Install with: scoop install bat'
Register-ToolWrapper -FunctionName 'fd' -CommandName 'fd' -InstallHint 'Install with: scoop install fd'
```

**Impact**:

- Reduces code duplication significantly
- Standardizes error handling
- Makes it easier to add new tool wrappers
- Improves maintainability

**Files Affected**:

- `profile.d/cli-modules/modern-cli.ps1` (8+ tools)
- All new modules using similar patterns

**Note**: After fragment numbering migration, this will be `profile.d/cli-modules/modern-cli.ps1` (no numbering).

---

### 2. Standardize Command Detection

**Problem**: Inconsistent use of command detection functions:

- Some use `Test-HasCommand`
- Some use `Get-Command` directly
- Some use `Test-CachedCommand`
- Some use `Test-Path Function:` checks

**Current State**:

- `Test-HasCommand` - Used in many fragments (1089 matches)
- `Test-CachedCommand` - Available but underutilized
- Direct `Get-Command` - Used in modern-cli.ps1

**Proposed Solution**: Standardize on `Test-CachedCommand` for all tool detection:

1. **Update all fragments** to use `Test-CachedCommand` instead of `Test-HasCommand`
2. **Deprecate `Test-HasCommand`** (or make it an alias to `Test-CachedCommand`)
3. **Update documentation** to recommend `Test-CachedCommand`

**Benefits**:

- Better performance (cached results)
- Consistent behavior across all modules
- Easier to maintain

**Migration Strategy**:

- Phase 1: Update new modules to use `Test-CachedCommand`
- Phase 2: Migrate existing modules during fragment renaming
- Phase 3: Remove `Test-HasCommand` (or make it an alias)

**Files Affected**: ~189 files with command detection

---

### 3. Standardize Module Loading Pattern (CRITICAL - Addresses Ongoing Issues)

**Problem**: The pattern for loading modules from subdirectories is repeated across multiple fragments and has several issues:

1. **Repetitive path validation** - Manual null checks, whitespace checks, Test-Path calls
2. **No path caching** - Same paths validated multiple times (performance issue)
3. **Inconsistent error handling** - Different error handling patterns
4. **No dependency validation** - Modules can load before dependencies
5. **No retry logic** - Transient failures cause permanent failures
6. **Hard to maintain** - Complex nested conditionals

**Current Pattern** (error-prone, repeated everywhere):

```powershell
try {
    $devToolsModulesDir = Join-Path $PSScriptRoot 'dev-tools-modules'
    if ($devToolsModulesDir -and -not [string]::IsNullOrWhiteSpace($devToolsModulesDir) -and (Test-Path -LiteralPath $devToolsModulesDir)) {
        $buildDir = Join-Path $devToolsModulesDir 'build'
        if ($buildDir -and -not [string]::IsNullOrWhiteSpace($buildDir) -and (Test-Path -LiteralPath $buildDir)) {
            $modulePath = Join-Path $buildDir 'build-tools.ps1'
            if ($modulePath -and -not [string]::IsNullOrWhiteSpace($modulePath) -and (Test-Path -LiteralPath $modulePath)) {
                try {
                    . $modulePath
                }
                catch {
                    # Error handling
                }
            }
        }
    }
}
catch {
    # Error handling
}
```

**Proposed Solution**: Create a comprehensive, robust module loading system. See `MODULE_LOADING_STANDARD.md` for complete specification.

**Core Functions**:

1. **`Import-FragmentModule`** - Robust module loading with:

   - Path validation and caching
   - Dependency checking
   - Error handling with context
   - Retry logic for transient failures
   - Performance optimization

2. **`Import-FragmentModules`** - Batch loading for multiple modules

3. **`Test-ModulePath`** - Validation helper without loading

**Usage**:

```powershell
# Simple loading
Import-FragmentModule -FragmentRoot $PSScriptRoot `
    -ModulePath @('dev-tools-modules', 'build', 'build-tools.ps1') `
    -Context "Fragment: build-tools (build-tools.ps1)" `
    -CacheResults

# With dependencies
Import-FragmentModule -FragmentRoot $PSScriptRoot `
    -ModulePath @('git-modules', 'enhanced', 'git-enhanced.ps1') `
    -Context "Fragment: git-enhanced" `
    -Dependencies @('bootstrap', 'env', 'git') `
    -Required

# Batch loading
Import-FragmentModules -FragmentRoot $PSScriptRoot -Modules @(
    @{ ModulePath = @('dev-tools-modules', 'build', 'build-tools.ps1'); Context = 'build-tools' },
    @{ ModulePath = @('dev-tools-modules', 'build', 'testing-frameworks.ps1'); Context = 'testing' }
)
```

**Benefits**:

- ✅ **~80% reduction in boilerplate code**
- ✅ **Path caching** - Significant performance improvement
- ✅ **Dependency validation** - Prevents load-order issues
- ✅ **Comprehensive error handling** - Detailed error messages with context
- ✅ **Retry logic** - Handles transient failures
- ✅ **Consistent behavior** - Standardized across all modules
- ✅ **Easier to maintain** - Single source of truth
- ✅ **Better debugging** - Detailed error context

**Files Affected**:

- `profile.d/testing.ps1` (currently `57-testing.ps1`)
- `profile.d/build-tools.ps1` (currently `58-build-tools.ps1`)
- `profile.d/modern-cli.ps1` (currently `54-modern-cli.ps1`)
- `profile.d/containers.ps1` (currently `22-containers.ps1`)
- `profile.d/files.ps1` (currently `02-files.ps1`) - **HIGH PRIORITY** (loads 100+ modules)
- All fragments loading submodules

**Implementation Priority**: **CRITICAL** - This addresses ongoing module loading issues and should be implemented first.

**See**: `MODULE_LOADING_STANDARD.md` for complete specification, implementation plan, and migration guide.

**Note**: Fragment names will change during numbering migration. Update references accordingly.

---

### 4. Standardize Function Registration Pattern

**Problem**: The pattern for registering functions and aliases is repeated:

```powershell
if (Get-Command -Name 'Set-AgentModeFunction' -ErrorAction SilentlyContinue) {
    Set-AgentModeFunction -Name 'Invoke-Aws' -Body ${function:Invoke-Aws}
}
else {
    Set-Item -Path Function:Invoke-Aws -Value ${function:Invoke-Aws} -ErrorAction SilentlyContinue
}

if (Get-Command -Name 'Set-AgentModeAlias' -ErrorAction SilentlyContinue) {
    Set-AgentModeAlias -Name 'aws' -Target 'Invoke-Aws'
}
else {
    Set-Alias -Name 'aws' -Value 'Invoke-Aws' -ErrorAction SilentlyContinue
}
```

**Proposed Solution**: Enhance `Set-AgentModeFunction` and `Set-AgentModeAlias` to handle fallback automatically, or create wrapper functions:

```powershell
# Enhanced bootstrap functions (already exist but could be improved)
# They already handle fallback, but usage could be simplified

# Current usage is already good, but we could add:
function Register-FragmentFunction {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$Name,

        [Parameter(Mandatory)]
        [scriptblock]$Body,

        [string[]]$Aliases = @()
    )

    Set-AgentModeFunction -Name $Name -Body $Body

    foreach ($alias in $Aliases) {
        Set-AgentModeAlias -Name $alias -Target $Name
    }
}
```

**Usage**:

```powershell
Register-FragmentFunction -Name 'Invoke-Aws' -Body ${function:Invoke-Aws} -Aliases @('aws')
```

**Benefits**:

- Cleaner code
- Less repetition
- Easier to add aliases

**Files Affected**: All fragments registering functions (71+ files)

---

## Medium Priority Refactorings

### 5. Extract Common Cloud Provider Pattern

**Problem**: AWS, Azure, and GCloud modules follow similar patterns but are implemented separately.

**Current**: Each has its own implementation of:

- Command wrapper
- Profile/account switching
- Region switching
- Credential management

**Proposed Solution**: Create a base cloud provider module:

```powershell
# profile.d/dev-tools-modules/cloud/cloud-base.ps1
function Register-CloudProvider {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$ProviderName,

        [Parameter(Mandatory)]
        [string]$CommandName,

        [string]$ProfileEnvVar,

        [string]$RegionEnvVar,

        [scriptblock]$CustomFunctions
    )

    # Register base wrapper
    Register-ToolWrapper -FunctionName "Invoke-$ProviderName" -CommandName $CommandName

    # Register profile switcher if env var provided
    if ($ProfileEnvVar) {
        Register-FragmentFunction -Name "Set-${ProviderName}Profile" -Body {
            param([string]$ProfileName)
            Set-Item -Path "env:$ProfileEnvVar" -Value $ProfileName
        }
    }

    # Register region switcher if env var provided
    if ($RegionEnvVar) {
        Register-FragmentFunction -Name "Set-${ProviderName}Region" -Body {
            param([string]$Region)
            Set-Item -Path "env:$RegionEnvVar" -Value $Region
        }
    }

    # Register custom functions
    if ($CustomFunctions) {
        & $CustomFunctions
    }
}
```

**Usage**:

```powershell
Register-CloudProvider -ProviderName 'Aws' -CommandName 'aws' `
    -ProfileEnvVar 'AWS_PROFILE' -RegionEnvVar 'AWS_REGION'
```

**Benefits**:

- Reduces duplication
- Consistent behavior across cloud providers
- Easier to add new cloud providers

**Files Affected**:

- `profile.d/aws.ps1` (currently `31-aws.ps1`)
- `profile.d/azure.ps1` (currently `50-azure.ps1`)
- `profile.d/gcloud.ps1` (currently `51-gcloud.ps1`)
- Future cloud provider modules (e.g., `cloud-enhanced.ps1`)

**Note**: Fragment names will change during numbering migration. Update references accordingly.

---

### 6. Standardize Language Module Pattern

**Problem**: Language modules (Go, Rust, Python, etc.) follow similar patterns but are implemented separately.

**Common Patterns**:

- Version management
- Build commands
- Test commands
- Package management

**Proposed Solution**: Create a base language module helper:

```powershell
# profile.d/dev-tools-modules/languages/language-base.ps1
function Register-LanguageModule {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [string]$LanguageName,

        [Parameter(Mandatory)]
        [string]$CommandName,

        [string]$BuildCommand = 'build',

        [string]$TestCommand = 'test',

        [string]$PackageManager = $null,

        [hashtable]$CustomCommands = @{}
    )

    # Register base wrapper
    Register-ToolWrapper -FunctionName "Invoke-$LanguageName" -CommandName $CommandName

    # Register build command
    Register-FragmentFunction -Name "Build-${LanguageName}Project" -Body {
        & $CommandName $BuildCommand @args
    }

    # Register test command
    Register-FragmentFunction -Name "Test-${LanguageName}Project" -Body {
        & $CommandName $TestCommand @args
    }

    # Register custom commands
    foreach ($cmd in $CustomCommands.Keys) {
        Register-FragmentFunction -Name $cmd -Body $CustomCommands[$cmd]
    }
}
```

**Benefits**:

- Consistent language module structure
- Easier to add new languages
- Standardized commands across languages

**Files Affected**: All language modules (13+ planned)

---

### 7. Consolidate Error Handling

**Problem**: Error handling patterns vary across fragments.

**Current**: Mix of:

- Try-catch with Write-Warning
- Try-catch with Write-ProfileError
- Try-catch with Exit-WithCode
- Silent failures

**Proposed Solution**: Standardize error handling helper:

```powershell
# Already exists but could be enhanced
# profile.d/bootstrap/ErrorHandling.ps1 (or bootstrap.ps1/bootstrap/ErrorHandling.ps1 after migration)

function Handle-FragmentError {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [System.Management.Automation.ErrorRecord]$ErrorRecord,

        [Parameter(Mandatory)]
        [string]$Context,

        [switch]$SuppressWarning
    )

    if ($env:PS_PROFILE_DEBUG) {
        if (Get-Command Write-ProfileError -ErrorAction SilentlyContinue) {
            Write-ProfileError -ErrorRecord $ErrorRecord -Context $Context -Category 'Fragment'
        }
        elseif (-not $SuppressWarning) {
            Write-Warning "$Context : $($ErrorRecord.Exception.Message)"
        }
    }
}
```

**Benefits**:

- Consistent error handling
- Better debugging experience
- Easier to maintain

---

## Low Priority Refactorings

### 8. Extract Conversion Module Pattern

**Problem**: Conversion modules have repetitive structure for format detection and conversion.

**Opportunity**: Create base conversion module helpers for common patterns.

**Impact**: Medium - affects many conversion modules but they're already well-structured

---

### 9. Consolidate Git Module Functions

**Problem**: Git functions are spread across multiple files (`git.ps1` - currently `11-git.ps1` and `44-git.ps1`, `git-modules/`).

**Opportunity**: Consolidate during fragment renaming migration. After migration, we'll have:

- `profile.d/git.ps1` (main fragment, consolidates current `11-git.ps1` and `44-git.ps1`)
- `profile.d/git-modules/core/` (core Git operations)
- `profile.d/git-modules/integrations/` (Git service integrations)
- `profile.d/git-enhanced.ps1` (enhanced Git tools - new module)

**Impact**: Low - works fine as-is, but consolidation would improve organization

**Migration Note**: During fragment renaming, consolidate `11-git.ps1` and `44-git.ps1` into a single `git.ps1` fragment.

---

### 10. Standardize Module Documentation

**Problem**: Module documentation format varies.

**Opportunity**: Create module documentation template and enforce via linting.

**Impact**: Low - documentation exists but format varies

---

## Implementation Strategy

### Phase 1: High Priority (During Fragment Migration)

**Timing**: Execute these refactorings as part of the fragment numbering migration (see `FRAGMENT_NUMBERING_MIGRATION.md`).

**CRITICAL**: Start with module loading standardization - this addresses ongoing issues.

1. **Standardize Module Loading Pattern** ⚠️ **CRITICAL - DO FIRST**

   - Create `Import-FragmentModule`, `Import-FragmentModules`, `Test-ModulePath` functions
   - Implement path caching for performance
   - Add dependency validation
   - Add retry logic for transient failures
   - **Priority order**:
     1. `02-files.ps1` → `files.ps1` (loads 100+ modules, highest impact)
     2. `22-containers.ps1` → `containers.ps1` (loads multiple modules)
     3. `57-testing.ps1` → `testing.ps1`
     4. `58-build-tools.ps1` → `build-tools.ps1`
     5. `54-modern-cli.ps1` → `modern-cli.ps1`
     6. All other fragments loading submodules
   - See `MODULE_LOADING_STANDARD.md` for complete specification

2. **Standardize Tool Wrapper Pattern**

   - Create `Register-ToolWrapper` function in `bootstrap/FunctionRegistration.ps1`
   - Update `modern-cli.ps1` (no numbering after migration) to use it
   - Update all new modules to use it
   - Update existing modules during fragment renaming

3. **Standardize Command Detection**

   - Migrate to `Test-CachedCommand` in all modules
   - Update fragments as they're renamed (e.g., `31-aws.ps1` → `aws.ps1`)
   - Update documentation
   - Consider making `Test-HasCommand` an alias to `Test-CachedCommand` for backward compatibility

### Phase 2: Medium Priority (After Migration)

**Timing**: Execute after fragment numbering migration is complete and fragments are renamed.

4. **Extract Common Patterns**
   - Cloud provider base module (affects `aws.ps1`, `azure.ps1`, `gcloud.ps1`, `cloud-enhanced.ps1`)
   - Language module base (affects all `lang-*.ps1` modules)
   - Standardize error handling across all renamed fragments

### Phase 3: Low Priority (Ongoing)

5. **Consolidate and Optimize**
   - Consolidate Git modules
   - Standardize documentation
   - Extract conversion patterns

---

## Benefits Summary

### Code Quality

- **Reduced duplication**: ~30-40% reduction in repetitive code
- **Consistency**: Standardized patterns across all modules
- **Maintainability**: Easier to update and fix issues

### Performance

- **Better caching**: Standardized use of `Test-CachedCommand`
- **Faster loading**: Optimized module loading patterns

### Developer Experience

- **Easier to add modules**: Use helper functions instead of copying code
- **Better error messages**: Consistent error handling
- **Clearer code**: Less boilerplate, more intent

---

## Migration Checklist

When refactoring each module during fragment renaming:

**Fragment Renaming** (see `FRAGMENT_NUMBERING_MIGRATION.md`):

- [ ] Rename fragment file (e.g., `31-aws.ps1` → `aws.ps1`)
- [ ] Update fragment declaration (dependencies, tier)
- [ ] Update all references to the fragment

**Refactoring Steps**:

- [ ] Replace tool wrappers with `Register-ToolWrapper`
- [ ] Replace `Test-HasCommand` with `Test-CachedCommand`
- [ ] Replace module loading with `Import-FragmentModule`
- [ ] Use `Register-FragmentFunction` for function registration
- [ ] Update error handling to use standard patterns
- [ ] Update fragment dependencies if needed
- [ ] Run tests to ensure no regressions
- [ ] Update documentation
- [ ] Update module expansion plan if module is completed

**Example Migration** (`31-aws.ps1` → `aws.ps1`):

1. Rename file: `31-aws.ps1` → `aws.ps1`
2. Add fragment declaration:
   ```powershell
   # Dependencies: bootstrap, env
   # Tier: standard
   ```
3. Replace `Test-HasCommand` with `Test-CachedCommand`
4. Use `Register-ToolWrapper` for AWS CLI wrapper
5. Update all references in documentation and other fragments
6. Run tests
7. Commit changes

---

## Fragment Naming After Migration

After removing numbering, fragments will use descriptive names with explicit dependencies:

**Current → New Naming Examples**:

- `00-bootstrap.ps1` → `bootstrap.ps1` (Tier: core)
- `01-env.ps1` → `env.ps1` (Tier: essential, Dependencies: bootstrap)
- `11-git.ps1` + `44-git.ps1` → `git.ps1` (consolidated, Tier: standard)
- `22-containers.ps1` → `containers.ps1` (Tier: standard)
- `31-aws.ps1` → `aws.ps1` (Tier: standard)
- `50-azure.ps1` → `azure.ps1` (Tier: standard)
- `51-gcloud.ps1` → `gcloud.ps1` (Tier: standard)
- `54-modern-cli.ps1` → `modern-cli.ps1` (Tier: standard)
- `57-testing.ps1` → `testing.ps1` (Tier: standard)
- `58-build-tools.ps1` → `build-tools.ps1` (Tier: standard)

**New Modules** (no numbering):

- `security-tools.ps1` (Tier: standard, Dependencies: bootstrap, env)
- `api-tools.ps1` (Tier: standard, Dependencies: bootstrap, env)
- `lang-rust.ps1` (Tier: standard, Dependencies: bootstrap, env)
- `game-emulators.ps1` (Tier: optional, Dependencies: bootstrap, env)

**Subdirectories** (unchanged):

- `profile.d/bootstrap/` (bootstrap helpers)
- `profile.d/cli-modules/`
- `profile.d/dev-tools-modules/`
- `profile.d/git-modules/`
- etc.

---

## Notes

- Refactorings should be done incrementally during fragment migration
- Each refactoring should be tested independently
- Maintain backward compatibility during migration (support both numbered and named fragments during transition)
- Update module expansion plan as patterns are standardized
- Update all fragment references in documentation when renaming
- Fragment dependencies are now explicit (no implicit ordering from numbers)
- Use `Get-FragmentLoadOrder` to verify correct load order after renaming
