# Type Safety in PowerShell

This guide outlines strategies for improving type safety in PowerShell codebases, with specific recommendations for this profile repository.

## Current State in This Repository

Type safety improvements are already in use across `scripts/lib/` and profile fragments:

- **Enums** — Defined in `scripts/lib/core/CommonEnums.psm1` (for example `ExitCode`, `LogLevel`, `TestSuite`, `SeverityLevel`, `FileSystemPathType`, `DatabaseStatus`) and `FragmentCommandType` in `scripts/lib/fragment/FragmentCommandRegistry.psm1`. Import `CommonEnums.psm1` before modules that reference these types.
- **Exit codes** — `scripts/lib/core/ExitCodes.psm1` exports `$EXIT_*` constants and `Exit-WithCode`. Prefer `[ExitCode]::Value` in modules; use `$EXIT_*` in `-File` scripts to avoid PowerShell argument-parsing quirks with enum syntax.
- **Classes** — `EventSamplingStats` (`profile.d/bootstrap/ErrorHandlingStandard.ps1`), `ModuleImportResult` (`profile.d/bootstrap/ModuleLoading.ps1`), `FragmentDependencyTestResult` (`scripts/lib/fragment/FragmentLoading.psm1`).
- **Validation** — `[ValidateNotNullOrEmpty()]` and enum-typed parameters on many lib functions; major `[ValidateSet()]` usages were converted to enums.
- **Strict mode** — Enabled in `tests/TestSupport.ps1` for all Pester tests. Lib modules adopt `Set-StrictMode -Version Latest` incrementally; global bootstrap strict mode is not enabled yet.
- **Generic returns** — `[object]` and `[OutputType([object])]` remain intentional on helpers like `Invoke-WithErrorHandling` and `Invoke-WithRetry` where return types vary.

The sections below describe patterns for new code and incremental hardening—not a backlog of unfinished migration work.

## PowerShell Type Safety Limitations

PowerShell is dynamically typed by default:

- Type annotations are **runtime checks**, not compile-time
- `[OutputType()]` is **documentation only** - doesn't enforce return types
- Variables can change types during execution
- No static type checking before execution

## Recommended Improvements

### 1. Enable Strict Mode

**Strict mode** catches common errors like uninitialized variables and non-existent properties.

```powershell
# Add to bootstrap or main profile
Set-StrictMode -Version Latest
```

**Considerations:**

- May break existing code that relies on dynamic behavior
- Should be tested incrementally
- Can be scoped to specific modules/fragments

**Implementation Strategy:**

```powershell
# Option 1: Enable globally in bootstrap
Set-StrictMode -Version Latest

# Option 2: Enable per-module (safer migration)
# In each module:
Set-StrictMode -Version Latest
```

### 2. Use PowerShell Classes for Complex Data Structures

**Classes** provide compile-time type checking and better IntelliSense.

**Current Pattern (Less Type-Safe):**

```powershell
function Get-Config {
    [OutputType([hashtable])]
    param()
    return @{
        ServerName = "localhost"
        Port = 8080
        UseSSL = $true
    }
}
```

**Improved Pattern (Type-Safe):**

```powershell
class ServerConfig {
    [string]$ServerName
    [int]$Port
    [bool]$UseSSL

    ServerConfig() {
        $this.ServerName = "localhost"
        $this.Port = 8080
        $this.UseSSL = $true
    }
}

function Get-Config {
    [OutputType([ServerConfig])]
    param()
    return [ServerConfig]::new()
}
```

**Benefits:**

- IntelliSense support
- Property validation
- Clearer contracts
- Better documentation

**Use Cases:**

- Configuration objects
- Return value structures
- Complex parameter objects
- State management

### 3. Use Enums for Constrained Values

**Enums** prevent invalid values and improve readability.

**Current Pattern:**

```powershell
function Set-LogLevel {
    param(
        [Parameter(Mandatory)]
        [string]$Level  # Could be "Debug", "Info", "Warning", "Error", or anything!
    )
}
```

**Improved Pattern:**

```powershell
enum LogLevel {
    Debug
    Info
    Warning
    Error
}

function Set-LogLevel {
    param(
        [Parameter(Mandatory)]
        [LogLevel]$Level  # Only valid enum values allowed
    )
}
```

**Use Cases:**

- Exit codes
- Log levels
- Status values
- Mode/state indicators

### 4. Add Validation Attributes

**Validation attributes** enforce constraints at parameter binding time.

**Available Attributes:**

- `[ValidateSet('Value1', 'Value2')]` - Only allow specific values
- `[ValidateRange(1, 100)]` - Numeric range validation
- `[ValidateLength(1, 50)]` - String length validation
- `[ValidateScript({ ... })]` - Custom validation logic
- `[ValidatePattern('regex')]` - Regex pattern matching
- `[ValidateNotNull()]` - Cannot be null
- `[ValidateNotNullOrEmpty()]` - Cannot be null or empty

**Example:**

```powershell
function Get-User {
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,

        [Parameter(Mandatory)]
        [ValidateRange(1, 120)]
        [int]$Age,

        [Parameter(Mandatory)]
        [ValidateSet('Active', 'Inactive', 'Pending')]
        [string]$Status
    )
}
```

### 5. Use More Specific Return Types

**Current Pattern:**

```powershell
function Get-Result {
    [OutputType([object])]  # Too generic
    param()
    return @{ Success = $true; Data = "result" }
}
```

**Improved Pattern:**

```powershell
class OperationResult {
    [bool]$Success
    [string]$Data
    [string]$ErrorMessage
}

function Get-Result {
    [OutputType([OperationResult])]
    param()
    return [OperationResult]@{
        Success = $true
        Data = "result"
    }
}
```

### 6. Leverage PSScriptAnalyzer for Type Checking

**PSScriptAnalyzer** can catch type-related issues.

**Enable Type-Related Rules:**

```powershell
# In PSScriptAnalyzerSettings.psd1
IncludeRules = @(
    'PSUseDeclaredVarsMoreThanAssignments',  # Catch typos
    'PSAvoidUsingEmptyCatchBlock',           # Ensure error handling
    'PSUseOutputTypeCorrectly'                # Verify OutputType matches return
)
```

**Custom Rules:**
Consider creating custom PSScriptAnalyzer rules for:

- Functions returning `[object]` that could be more specific
- Missing validation attributes on parameters
- Missing `[OutputType()]` attributes

### 7. Use Type Accelerators and Type Constraints

**Type accelerators** provide shortcuts for common types:

```powershell
# Instead of [System.Collections.Generic.List[string]]
[list[string]]$items = @()

# Instead of [System.Collections.Generic.Dictionary[string, object]]
[hashtable]$config = @{}
```

**Type constraints** in variable declarations:

```powershell
[string]$name = "test"  # Variable can only hold strings
[int]$count = 0         # Variable can only hold integers
```

## Examples for This Codebase

### Example 1: Fragment Command Registry

**Current:**

```powershell
function Register-FragmentCommand {
    [OutputType([bool])]
    param(
        [string]$CommandName,
        [string]$FragmentName,
        [string]$CommandType  # Could be anything
    )
}
```

**Improved:**

```powershell
enum CommandType {
    Function
    Alias
    Cmdlet
    Application
}

function Register-FragmentCommand {
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandName,

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$FragmentName,

        [Parameter(Mandatory)]
        [CommandType]$CommandType  # Type-safe enum
    )
}
```

### Example 2: Error Handling Result

**Current:**

```powershell
function Exit-WithCode {
    [OutputType([void])]
    param(
        [int]$ExitCode,  # Could be any integer
        [string]$Message
    )
}
```

**Improved:**

```powershell
enum ExitCode {
    Success = 0
    ValidationFailure = 1
    SetupError = 2
    RuntimeError = 3
}

function Exit-WithCode {
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ExitCode]$ExitCode,  # Only valid exit codes

        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$Message
    )
}
```

### Example 3: Module Loading Result

**Current:**

```powershell
function Import-FragmentModules {
    [OutputType([hashtable])]
    param()
    return @{
        SuccessCount = 5
        FailureCount = 2
        Errors = @()
    }
}
```

**Improved:**

```powershell
class ModuleImportResult {
    [int]$SuccessCount
    [int]$FailureCount
    [System.Collections.Generic.List[string]]$Errors

    ModuleImportResult() {
        $this.SuccessCount = 0
        $this.FailureCount = 0
        $this.Errors = [System.Collections.Generic.List[string]]::new()
    }

    [bool]IsSuccess() {
        return $this.FailureCount -eq 0
    }
}

function Import-FragmentModules {
    [OutputType([ModuleImportResult])]
    param()
    return [ModuleImportResult]@{
        SuccessCount = 5
        FailureCount = 2
        Errors = [System.Collections.Generic.List[string]]::new()
    }
}
```

## Testing Type Safety

### Unit Tests

```powershell
Describe "Type Safety" {
    It "Should reject invalid enum values" {
        { Set-LogLevel -Level "Invalid" } | Should -Throw
    }

    It "Should accept valid enum values" {
        { Set-LogLevel -Level "Info" } | Should -Not -Throw
    }

    It "Should return correct type" {
        $result = Get-Config
        $result | Should -BeOfType [ServerConfig]
    }
}
```

### PSScriptAnalyzer

```powershell
# Run analyzer with type-focused rules
Invoke-ScriptAnalyzer -Path . -IncludeRule @(
    'PSUseOutputTypeCorrectly',
    'PSUseDeclaredVarsMoreThanAssignments'
)
```

## Tools and Resources

- **PSScriptAnalyzer**: Static analysis for PowerShell
- **PowerShell Classes**: [Microsoft Docs](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_classes)
- **Strict Mode**: `Get-Help Set-StrictMode -Full`
- **Validation Attributes**: `Get-Help about_Functions_Advanced_Parameters`

## Checklist for New Code

When adding or refactoring functions:

- Prefer existing enums in `CommonEnums.psm1` over new `[ValidateSet()]` attributes
- Add `[ValidateNotNullOrEmpty()]` on required string paths and names
- Use typed classes instead of hashtables when the shape is stable
- Enable `Set-StrictMode -Version Latest` in new `scripts/lib/` modules
- Document `[object]` parameters when flexibility is intentional
- Add Pester tests that reject invalid enum values

## Conclusion

While PowerShell will never be as type-safe as statically-typed languages, these improvements significantly enhance:

- **Code reliability** - Catch errors earlier
- **Developer experience** - Better IntelliSense and autocomplete
- **Maintainability** - Clearer contracts and documentation
- **Debugging** - Type mismatches caught at binding time

Start with low-risk improvements (validation attributes, enums) and gradually adopt stricter patterns (classes, strict mode) as the codebase evolves.
