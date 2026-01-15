<#
.SYNOPSIS
    Practical examples demonstrating type safety improvements in PowerShell.

.DESCRIPTION
    This file shows before/after examples of improving type safety in PowerShell code.
    These examples can be used as templates when refactoring existing code.

.NOTES
    These are examples only - not meant to be executed directly.
#>

# ===============================================
# Example 1: Exit Codes (Enum vs Constants)
# ===============================================

# BEFORE: Using integer constants (less type-safe)
# Current pattern in scripts/lib/core/ExitCodes.psm1
$script:EXIT_SUCCESS = 0
$script:EXIT_VALIDATION_FAILURE = 1
$script:EXIT_SETUP_ERROR = 2
$script:EXIT_OTHER_ERROR = 3

function Exit-WithCode-Before {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [int]$ExitCode  # Could be any integer - no validation!
    )
    exit $ExitCode
}

# Problem: Can call with invalid values
# Exit-WithCode-Before -ExitCode 999  # No error, but invalid!

# AFTER: Using enum (type-safe)
enum ExitCode {
    Success = 0
    ValidationFailure = 1
    SetupError = 2
    OtherError = 3
    TestFailure = 4
    TestTimeout = 5
    CoverageFailure = 6
    NoTestsFound = 7
    WatchModeCanceled = 8
}

function Exit-WithCode-After {
    [CmdletBinding()]
    [OutputType([void])]
    param(
        [Parameter(Mandatory)]
        [ExitCode]$ExitCode  # Only valid enum values allowed!
    )
    exit [int]$ExitCode
}

# Benefits:
# - IntelliSense shows available values
# - Invalid values rejected at parameter binding time
# - Self-documenting code
# Exit-WithCode-After -ExitCode [ExitCode]::Success  # ✅ Valid
# Exit-WithCode-After -ExitCode 999  # ❌ Error: Cannot convert value "999" to type "ExitCode"

# ===============================================
# Example 2: Command Types (Enum vs String)
# ===============================================

# BEFORE: String parameter (error-prone)
function Register-FragmentCommand-Before {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [string]$CommandName,
        
        [Parameter(Mandatory)]
        [string]$CommandType  # Could be "Function", "Alias", or anything!
    )
    
    # Manual validation needed
    $validTypes = @('Function', 'Alias', 'Cmdlet', 'Application')
    if ($CommandType -notin $validTypes) {
        throw "Invalid CommandType: $CommandType"
    }
    
    # ... rest of function
}

# AFTER: Enum parameter (type-safe)
enum CommandType {
    Function
    Alias
    Cmdlet
    Application
}

function Register-FragmentCommand-After {
    [CmdletBinding()]
    [OutputType([bool])]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$CommandName,
        
        [Parameter(Mandatory)]
        [CommandType]$CommandType  # Only valid enum values!
    )
    
    # No manual validation needed - PowerShell handles it
    # ... rest of function
}

# ===============================================
# Example 3: Complex Return Types (Class vs Hashtable)
# ===============================================

# BEFORE: Hashtable return (less type-safe)
function Import-FragmentModules-Before {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param(
        [string[]]$Modules
    )
    
    return @{
        SuccessCount = 5
        FailureCount = 2
        Errors = @('Error1', 'Error2')
        # Problem: No guarantee of structure, typos possible
        # SucessCount = 5  # Typo - no error!
    }
}

# AFTER: Class return (type-safe)
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
    
    [double]GetSuccessRate() {
        $total = $this.SuccessCount + $this.FailureCount
        if ($total -eq 0) { return 0.0 }
        return $this.SuccessCount / $total
    }
}

function Import-FragmentModules-After {
    [CmdletBinding()]
    [OutputType([ModuleImportResult])]
    param(
        [string[]]$Modules
    )
    
    $result = [ModuleImportResult]::new()
    $result.SuccessCount = 5
    $result.FailureCount = 2
    $result.Errors.Add('Error1')
    $result.Errors.Add('Error2')
    
    return $result
}

# Benefits:
# - IntelliSense for properties
# - Compile-time property name checking
# - Can add methods for behavior
# - Self-documenting structure

# ===============================================
# Example 4: Validation Attributes
# ===============================================

# BEFORE: Manual validation
function Get-User-Before {
    [CmdletBinding()]
    param(
        [string]$UserName,
        [int]$Age,
        [string]$Status
    )
    
    # Manual validation scattered throughout function
    if ([string]::IsNullOrWhiteSpace($UserName)) {
        throw "UserName cannot be empty"
    }
    
    if ($Age -lt 1 -or $Age -gt 120) {
        throw "Age must be between 1 and 120"
    }
    
    $validStatuses = @('Active', 'Inactive', 'Pending')
    if ($Status -notin $validStatuses) {
        throw "Status must be one of: $($validStatuses -join ', ')"
    }
    
    # ... rest of function
}

# AFTER: Validation attributes (cleaner, earlier validation)
enum UserStatus {
    Active
    Inactive
    Pending
}

function Get-User-After {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ValidateNotNullOrEmpty()]
        [string]$UserName,
        
        [Parameter(Mandatory)]
        [ValidateRange(1, 120)]
        [int]$Age,
        
        [Parameter(Mandatory)]
        [UserStatus]$Status  # Enum provides validation automatically
    )
    
    # Validation happens automatically at parameter binding time
    # ... rest of function
}

# Benefits:
# - Validation happens before function body executes
# - Clearer, more declarative code
# - Consistent error messages
# - Less boilerplate

# ===============================================
# Example 5: Configuration Objects
# ===============================================

# BEFORE: Hashtable configuration
function Initialize-Service-Before {
    [CmdletBinding()]
    param(
        [hashtable]$Config
    )
    
    # No guarantee of structure
    $serverName = $Config.ServerName  # Could be null!
    $port = $Config.Port  # Could be wrong type!
    $useSSL = $Config.UseSSL  # Typo possible: UseSsl vs UseSSL
}

# AFTER: Class configuration
class ServiceConfig {
    [Parameter(Mandatory)]
    [ValidateNotNullOrEmpty()]
    [string]$ServerName
    
    [Parameter(Mandatory)]
    [ValidateRange(1, 65535)]
    [int]$Port
    
    [bool]$UseSSL = $false
    
    [ValidateSet('http', 'https')]
    [string]$Protocol = 'http'
    
    ServiceConfig() {
        # Default constructor
    }
    
    ServiceConfig([string]$serverName, [int]$port) {
        $this.ServerName = $serverName
        $this.Port = $port
    }
    
    [string]GetConnectionString() {
        $protocol = if ($this.UseSSL) { 'https' } else { 'http' }
        return "$protocol://$($this.ServerName):$($this.Port)"
    }
}

function Initialize-Service-After {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory)]
        [ServiceConfig]$Config
    )
    
    # Type-safe access to properties
    $serverName = $Config.ServerName  # Guaranteed to exist and be string
    $port = $Config.Port  # Guaranteed to be int
    $useSSL = $Config.UseSSL  # Guaranteed to be bool
    
    $connectionString = $Config.GetConnectionString()  # Method available via IntelliSense
}

# ===============================================
# Example 6: Event Sampling Stats (Current vs Improved)
# ===============================================

# CURRENT: From ErrorHandlingStandard.ps1
function Get-EventSamplingStats-Current {
    [CmdletBinding()]
    [OutputType([hashtable])]
    param()
    
    return @{
        TotalEvents         = 100
        ErrorCount          = 5
        SlowRequestCount    = 10
        SampledSuccessCount = 85
        KeptEvents          = 20
        ErrorRetentionRate  = 1.0
        SuccessSamplingRate = 0.8947
    }
}

# IMPROVED: Using class
class EventSamplingStats {
    [int]$TotalEvents
    [int]$ErrorCount
    [int]$SlowRequestCount
    [int]$SampledSuccessCount
    [int]$KeptEvents
    [double]$ErrorRetentionRate
    [double]$SuccessSamplingRate
    
    EventSamplingStats() {
        $this.TotalEvents = 0
        $this.ErrorCount = 0
        $this.SlowRequestCount = 0
        $this.SampledSuccessCount = 0
        $this.KeptEvents = 0
        $this.ErrorRetentionRate = 0.0
        $this.SuccessSamplingRate = 0.0
    }
    
    [double]GetErrorRate() {
        if ($this.TotalEvents -eq 0) { return 0.0 }
        return $this.ErrorCount / $this.TotalEvents
    }
    
    [double]GetSlowRequestRate() {
        if ($this.TotalEvents -eq 0) { return 0.0 }
        return $this.SlowRequestCount / $this.TotalEvents
    }
    
    [string]ToString() {
        return "Events: $($this.TotalEvents), Errors: $($this.ErrorCount), Slow: $($this.SlowRequestCount)"
    }
}

function Get-EventSamplingStats-Improved {
    [CmdletBinding()]
    [OutputType([EventSamplingStats])]
    param()
    
    $stats = [EventSamplingStats]@{
        TotalEvents         = 100
        ErrorCount          = 5
        SlowRequestCount    = 10
        SampledSuccessCount = 85
        KeptEvents          = 20
        ErrorRetentionRate  = 1.0
        SuccessSamplingRate = 0.8947
    }
    
    return $stats
}

# Usage:
# $stats = Get-EventSamplingStats-Improved
# $stats.GetErrorRate()  # IntelliSense shows available methods
# $stats.ToString()  # Custom string representation

# ===============================================
# Example 7: Strict Mode Benefits
# ===============================================

# WITHOUT Strict Mode (current default)
function Process-Data-WithoutStrict {
    param([string]$Input)
    
    # Typo in variable name - no error until runtime!
    $procesedData = $Input.ToUpper()  # Typo: "procesed" instead of "processed"
    return $procesedData  # Returns null if typo exists
}

# WITH Strict Mode
Set-StrictMode -Version Latest

function Process-Data-WithStrict {
    param([string]$Input)
    
    # Typo caught immediately!
    # $procesedData = $Input.ToUpper()  # Error: Variable 'procesedData' is not defined
    $processedData = $Input.ToUpper()  # Correct spelling
    return $processedData
}

# Benefits of Strict Mode:
# - Catches typos in variable names
# - Prevents accessing non-existent properties
# - Forces explicit variable initialization
# - Catches calling non-existent methods

# ===============================================
# Example 8: Generic Collections with Type Safety
# ===============================================

# BEFORE: Unconstrained arrays
function Process-Items-Before {
    param([object[]]$Items)  # Could be anything!
    
    foreach ($item in $Items) {
        # No guarantee $item has .Name property
        Write-Output $item.Name  # Could fail at runtime
    }
}

# AFTER: Type-constrained collections
function Process-Items-After {
    param([string[]]$Items)  # Only strings allowed
    
    foreach ($item in $Items) {
        # $item is guaranteed to be a string
        Write-Output $item.ToUpper()
    }
}

# For complex types, use generic lists:
function Process-Configs-After {
    param([System.Collections.Generic.List[ServiceConfig]]$Configs)
    
    foreach ($config in $Configs) {
        # $config is guaranteed to be ServiceConfig
        Write-Output $config.GetConnectionString()
    }
}

# ===============================================
# Summary: Migration Checklist
# ===============================================

<#
When improving type safety:

1. ✅ Identify string parameters that should be enums
   - Look for ValidateSet or manual validation
   - Common: Status, Type, Level, Mode

2. ✅ Find functions returning [object] or [hashtable]
   - Consider creating classes for complex return types
   - Especially if structure is reused

3. ✅ Add validation attributes to parameters
   - [ValidateNotNullOrEmpty()] for required strings
   - [ValidateRange()] for numeric bounds
   - [ValidateSet()] or enum for constrained values

4. ✅ Enable strict mode incrementally
   - Start with new modules/fragments
   - Test thoroughly before enabling globally

5. ✅ Replace magic numbers/strings with enums
   - Exit codes → ExitCode enum
   - Status values → Status enum
   - Log levels → LogLevel enum

6. ✅ Use classes for configuration objects
   - ServiceConfig, ModuleConfig, etc.
   - Provides IntelliSense and validation
#>
