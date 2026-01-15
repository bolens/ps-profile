# Error Handling Standardization

This document describes the standardized error handling approach implemented in Phase 6, following [OpenTelemetry semantic conventions](https://opentelemetry.io/docs/specs/otel/error-handling/) and the [wide events philosophy](https://loggingsucks.com/).

## Overview

The error handling standardization provides:

1. **Structured Wide Events**: One comprehensive event per operation with all context
2. **OpenTelemetry Compliance**: Follows semantic conventions for error recording
3. **Tail Sampling**: Always keep errors, sample successful operations intelligently
4. **Business Context**: Include user context, feature flags, and business metrics
5. **Consistent API**: Standardized functions across all modules

## Key Principles

### 1. Wide Events Philosophy

Instead of scattered log lines, we create **one comprehensive event per operation** that includes:

- **Technical context**: Duration, status codes, error details
- **Business context**: User IDs, request IDs, feature flags, transaction details
- **Operation context**: Service name, version, deployment environment
- **Invocation context**: Script name, function name, line numbers

### 2. OpenTelemetry Semantic Conventions

All events follow OpenTelemetry standards:

- **Standard fields**: `timestamp`, `severity`, `service_name`, `service_version`
- **Error recording**: Exception type, message, stack trace, status codes
- **Span naming**: Operation names follow `service.operation` pattern (e.g., `aws.s3.upload`)
- **Status codes**: `OK`, `ERROR` with descriptive messages

### 3. Tail Sampling

Events are sampled **after** the operation completes, based on outcome:

- ✅ **Always keep**: Errors (100% retention)
- ✅ **Always keep**: Slow requests (above p99 threshold, default 2000ms)
- ✅ **Always keep**: VIP users (configurable)
- ✅ **Always keep**: Explicitly marked events (`-AlwaysKeep`)
- ⚠️ **Sample**: Successful operations (default 5% sampling rate)

This ensures you never lose critical events while managing costs.

## Functions

### Write-WideEvent

Emits a structured wide event with comprehensive context.

```powershell
Write-WideEvent -EventName "aws.s3.upload" -Level INFO -Context @{
    user_id = "user_123"
    bucket = "my-bucket"
    key = "file.txt"
    size_bytes = 1024
    region = "us-east-1"
} -DurationMs 250
```

**Parameters:**

- `-EventName`: Operation name (OpenTelemetry span name)
- `-Level`: Log level (`DEBUG`, `INFO`, `WARN`, `ERROR`, `FATAL`)
- `-Context`: Hashtable of contextual data
- `-ErrorRecord`: Optional ErrorRecord (always kept if provided)
- `-DurationMs`: Operation duration in milliseconds
- `-AlwaysKeep`: Force keeping this event
- `-SampleRate`: Sampling rate for success (default 0.05)

**Returns:** `$true` if event was kept, `$false` if sampled out

### Write-StructuredError

Records an error following OpenTelemetry conventions. Errors are always kept.

```powershell
try {
    $result = Invoke-Aws s3 ls
}
catch {
    Write-StructuredError -ErrorRecord $_ -OperationName "aws.s3.list" -Context @{
        bucket = "my-bucket"
        region = "us-east-1"
    } -StatusCode 500 -Retriable
}
```

**Parameters:**

- `-ErrorRecord`: The ErrorRecord to record (mandatory)
- `-Context`: Additional context hashtable
- `-OperationName`: Operation name (OpenTelemetry span name)
- `-StatusCode`: HTTP or operation status code
- `-Retriable`: Whether the error is retriable

### Write-StructuredWarning

Records a warning with structured context.

```powershell
Write-StructuredWarning -Message "Slow query detected" -OperationName "database.query" -Context @{
    query = "SELECT * FROM users"
    duration_ms = 2500
} -Code "SLOW_QUERY"
```

**Parameters:**

- `-Message`: Warning message (mandatory)
- `-Context`: Additional context hashtable
- `-OperationName`: Operation name
- `-Code`: Warning code for categorization

### Invoke-WithWideEvent

Wraps an operation with automatic wide event tracking.

```powershell
$result = Invoke-WithWideEvent -OperationName "aws.s3.upload" -Context @{
    bucket = "my-bucket"
    key = "file.txt"
} -ScriptBlock {
    aws s3 cp file.txt s3://my-bucket/file.txt
}
```

**Parameters:**

- `-OperationName`: Operation name (mandatory)
- `-ScriptBlock`: Script block to execute (mandatory)
- `-Context`: Initial context hashtable
- `-Level`: Log level for successful operations (default `INFO`)
- `-AlwaysKeep`: Force keeping this event

**Returns:** Result from ScriptBlock execution

### Get-EventSamplingStats

Gets statistics about event sampling.

```powershell
$stats = Get-EventSamplingStats
# Returns:
# {
#     TotalEvents = 1000
#     ErrorCount = 5
#     SlowRequestCount = 12
#     SampledSuccessCount = 49
#     KeptEvents = 66
#     ErrorRetentionRate = 1.0
#     SuccessSamplingRate = 0.049
# }
```

### Clear-EventCollection

Clears the collected wide events.

```powershell
$cleared = Clear-EventCollection
# Returns number of events cleared
```

## Migration Guide

### Step 1: Replace Write-Error with Write-StructuredError

**Before:**

```powershell
try {
    $result = Get-AwsResources -Type 's3'
}
catch {
    Write-Error "Failed to get AWS resources: $_"
}
```

**After:**

```powershell
try {
    $result = Get-AwsResources -Type 's3'
}
catch {
    Write-StructuredError -ErrorRecord $_ -OperationName "aws.resources.list" -Context @{
        resource_type = "s3"
    }
}
```

### Step 2: Replace Write-Warning with Write-StructuredWarning

**Before:**

```powershell
if ($duration -gt 2000) {
    Write-Warning "Slow operation detected: $duration ms"
}
```

**After:**

```powershell
if ($duration -gt 2000) {
    Write-StructuredWarning -Message "Slow operation detected" -OperationName "operation.name" -Context @{
        duration_ms = $duration
    } -Code "SLOW_OPERATION"
}
```

### Step 3: Wrap Operations with Invoke-WithWideEvent

**Before:**

```powershell
$startTime = Get-Date
try {
    $result = Invoke-DatabaseQuery -Query $query
    $duration = ((Get-Date) - $startTime).TotalMilliseconds
    Write-Verbose "Query completed in $duration ms"
}
catch {
    Write-Error "Query failed: $_"
}
```

**After:**

```powershell
$result = Invoke-WithWideEvent -OperationName "database.query" -Context @{
    query = $query
    database = "production"
} -ScriptBlock {
    Invoke-DatabaseQuery -Query $query
}
```

### Step 4: Add Business Context

Include business context in events:

```powershell
Write-WideEvent -EventName "checkout.process" -Level INFO -Context @{
    # Business context
    user_id = $user.Id
    user_subscription = $user.Subscription
    account_age_days = (Get-Date) - $user.CreatedAt
    lifetime_value_cents = $user.LTV

    # Operation context
    cart_id = $cart.Id
    item_count = $cart.Items.Count
    total_cents = $cart.Total
    coupon_applied = $cart.Coupon?.Code

    # Technical context
    payment_method = $payment.Method
    payment_provider = $payment.Provider
    attempt = $payment.AttemptNumber
} -DurationMs $duration
```

## Debug Messages and Output Standardization

This section defines the standard approach for debug messages, logging, and console output across the codebase.

### Debug Levels

The profile supports three levels of debug output via the `PS_PROFILE_DEBUG` environment variable:

#### Level 0: Disabled (Default)

- No debug output
- Set: `PS_PROFILE_DEBUG=0` or leave unset

#### Level 1: Basic Debug

- Shows fragment loading, warnings, and errors
- Basic operational information
- Set: `PS_PROFILE_DEBUG=1` or `PS_PROFILE_DEBUG=true`

#### Level 2: Verbose Debug

- Includes all Level 1 output
- Adds timing information for fragment loading
- Cache hit/miss information
- More detailed operation context
- Set: `PS_PROFILE_DEBUG=2`

#### Level 3: Performance Profiling

- Includes all Level 2 output
- Detailed metrics and timing breakdowns
- Performance analysis data
- Granular sub-operation timing
- Set: `PS_PROFILE_DEBUG=3`

### Debug Level Checking Pattern

**Always** use this standardized pattern for checking debug levels. Parse the debug level once at the start of your function or script block:

```powershell
# Parse debug level once at function/script start
$debugLevel = 0
if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
    # Debug is enabled, $debugLevel contains the numeric level (1-3)
}

# Then check levels as needed
if ($debugLevel -ge 1) {
    # Level 1+ output
    Write-Verbose "[operation.name] Basic debug message"
}

if ($debugLevel -ge 2) {
    # Level 2+ output (includes timing, cache info)
    Write-Verbose "[operation.name] Verbose debug with timing: ${duration}ms"
}

if ($debugLevel -ge 3) {
    # Level 3+ output (detailed performance metrics)
    Write-Host "  [operation.name] Performance: step1=${step1}ms, step2=${step2}ms, total=${total}ms" -ForegroundColor DarkGray
}
```

**Important**: Always check `$debugLevel` before emitting debug output. Never emit debug messages without checking the debug level first.

### When to Use Write-Verbose vs Write-Host

#### Use Write-Host For Debug Messages (Level 2+):

**Standard Practice**: Use `Write-Host` with structured prefixes and color coding for all debug output (Level 2+) to maintain consistency with the profile's debug output style.

1. **Level 2+ debug output**: General operational messages, timing information, cache diagnostics, detailed operation context

   - **Always** use `-ForegroundColor DarkGray` for debug output
   - **Always** indent with 2 spaces for visual hierarchy
   - **Always** prefix with operation tag in brackets: `[operation.name]`
   - **Format**: `Write-Host "  [operation.name] Message content" -ForegroundColor DarkGray`
   - **Check debug level**: Always check `$debugLevel -ge 2` before output

2. **Level 3 performance metrics**: Detailed profiling data, sub-operation breakdowns, granular metrics

   - Same format as Level 2, but check `$debugLevel -ge 3`
   - **Format**: `Write-Host "  [operation.name] Performance details" -ForegroundColor DarkGray`

**Examples:**

```powershell
# ✅ Level 2: General debug messages
if ($debugLevel -ge 2) {
    Write-Host "  [fragment-cache] Using ExportedFunctions workaround (Get-Command -Module failed but function is exported)" -ForegroundColor DarkGray
}

# ✅ Level 2: Timing information
if ($debugLevel -ge 2) {
    Write-Host "  [operation.name] Operation completed in ${duration}ms" -ForegroundColor DarkGray
}

# ✅ Level 3: Detailed performance metrics
if ($debugLevel -ge 3) {
    Write-Host "  [cache] Hit rate: 95%, Misses: 5, Total: 100" -ForegroundColor DarkGray
    Write-Host "  [cache] Performance breakdown - step1=${s1}ms, step2=${s2}ms, total=${total}ms" -ForegroundColor DarkGray
}
```

#### Use Write-Verbose For:

1. **Legacy compatibility**: Only when maintaining compatibility with existing code that uses `Write-Verbose`
2. **Messages that should be suppressed by default**: When you specifically want PowerShell's verbose preference to control visibility

**Note**: New code should prefer `Write-Host` with structured prefixes for consistency with the profile's debug output style.

#### Use Write-Host For User-Facing Messages:

1. **User-facing informational messages** (not debug-related):

   - Interactive script output that users need to see immediately
   - Status updates in utility scripts (e.g., "Processing files...")
   - Progress indicators
   - **Note**: These should NOT check `PS_PROFILE_DEBUG` - they're always shown
   - Use appropriate colors: Cyan for info, Yellow for warnings, Green for success

2. **Error display** (when structured error handling is not available):
   - Only as a fallback when `Write-StructuredError` is unavailable
   - Should still check debug level for error details
   - **Exception**: Formatted error messages may use `Write-Host` with `-ForegroundColor Red` at Level 1+ for visibility (errors should be prominently displayed)

**Examples of appropriate Write-Host usage:**

```powershell
# ✅ User-facing status (no debug check needed)
Write-Host "Processing 100 files..." -ForegroundColor Cyan

# ✅ Level 2+ debug messages (with debug check)
if ($debugLevel -ge 2) {
    Write-Host "  [fragment-cache] Cache initialization completed" -ForegroundColor DarkGray
}

# ✅ Level 3 performance metrics (with debug check)
if ($debugLevel -ge 3) {
    Write-Host "  [cache] Hit rate: 95%, Misses: 5" -ForegroundColor DarkGray
}

# ✅ Informational diagnostics (Blue)
if ($debugLevel -ge 2) {
    Write-Host "  [Cache] Content Entries: 126" -ForegroundColor Blue
}

# ✅ Special debug tracing (Magenta, Level 3+ only)
if ($debugLevel -ge 3) {
    Write-Host "  [fragment-registry.wrapper] Function call trace..." -ForegroundColor Magenta
}

# ✅ Error display (exception - errors should be visible)
if ($debugLevel -ge 1) {
    Write-Host $formattedError -ForegroundColor Red
}

# ✅ Success indicator (Green)
Write-Host "  [Cache] Cache hit for key: $key" -ForegroundColor Green

# ✅ Warning indicator (Yellow)
Write-Host "  [Cache] Cache miss for key: $key" -ForegroundColor Yellow

# ❌ WRONG - Debug message without checking level
Write-Host "[debug] Cache hit" -ForegroundColor Green  # Should check debug level first
```

### Debug Output Guidelines

1. **Level 1 (Basic)**:

   - Generally minimal output at this level
   - Use `Write-Host` with `-ForegroundColor DarkGray` if needed for important status updates
   - Include operation tags: `[operation.name]`
   - Check `$debugLevel -ge 1` before output
   - Format: `Write-Host "  [operation.name] Message" -ForegroundColor DarkGray`

2. **Level 2 (Verbose)**:

   - Use `Write-Host` with `-ForegroundColor DarkGray` for timing and cache information
   - Include operation tags and relevant metrics
   - Indent with 2 spaces for visual hierarchy
   - Check `$debugLevel -ge 2` before output
   - Format: `Write-Host "  [operation.name] Verbose details: ${metric}" -ForegroundColor DarkGray`

3. **Level 3 (Performance)**:

   - Use `Write-Host` with `-ForegroundColor DarkGray` for detailed metrics
   - Indent with 2 spaces for visual hierarchy
   - Check `$debugLevel -ge 3` before output
   - Format: `Write-Host "  [operation.name] Performance details: step1=${s1}ms, step2=${s2}ms" -ForegroundColor DarkGray`

4. **Errors**:

   - Always use `Write-StructuredError` regardless of debug level
   - Fallback to `Write-Error` only if structured error handling unavailable
   - **Error Display Exception**: When displaying formatted error messages at debug Level 1+, you may use `Write-Host` with `-ForegroundColor Red` to ensure errors are prominently visible:
     ```powershell
     if ($debugLevel -ge 1) {
         Write-Host $formattedError -ForegroundColor Red
     }
     ```
   - Additional debug details should use `Write-Host` with `-ForegroundColor DarkGray` and level checks

5. **Warnings**:
   - Use `Write-StructuredWarning` for structured warnings
   - Use `Write-Warning` only for simple fallback cases
   - Additional debug details can use `Write-Host` with `-ForegroundColor DarkGray` and level checks

### Message Formatting Standards

#### Operation Tags

All debug messages must include an operation tag in brackets:

```powershell
# ✅ CORRECT
Write-Verbose "[fragment-cache] Cache hit for key: $key"
Write-Verbose "[profile.loader] Loading fragment: $fragmentName"

# ❌ WRONG
Write-Verbose "Cache hit for key: $key"  # Missing operation tag
```

#### Indentation

- **All debug output (Level 2+)**: Always indent with 2 spaces for visual hierarchy
- **User-facing messages**: No indentation (unless part of a structured output)

```powershell
# Level 2+ debug messages
if ($debugLevel -ge 2) {
    Write-Host "  [operation] Main message" -ForegroundColor DarkGray
}

# Level 3 detailed breakdown
if ($debugLevel -ge 3) {
    Write-Host "  [operation] Detailed breakdown: step1=${s1}ms, step2=${s2}ms" -ForegroundColor DarkGray
}

# User-facing (no indentation)
Write-Host "Processing files..." -ForegroundColor Cyan
```

#### Color Guidelines

The profile uses a comprehensive color scheme to provide clear visual feedback for different types of messages:

##### Standard Colors

- **Green**: Success indicators

  - Cache hits, commands found, SQLite available, functions available
  - Module imports successful, operations completed successfully
  - Example: `Write-Host "  [Cache] Cache hit for key: $key" -ForegroundColor Green`

- **Yellow**: Warnings

  - Cache misses, missing modules, SQLite unavailable
  - No commands found, fallback paths being used
  - Example: `Write-Host "  [Cache] Cache miss for key: $key" -ForegroundColor Yellow`

- **Red**: Errors

  - Import failures, pre-registration failures, function not found
  - Critical errors that require attention
  - Example: `Write-Host "  [fragment-registry] Failed to import module" -ForegroundColor Red`

- **Cyan**: Status/Headers/Important Operations

  - Section headers, important status updates, operation start/end
  - User-facing informational messages
  - Example: `Write-Host "[fragment-registry.cache-stats] Cache usage statistics" -ForegroundColor Cyan`

- **Blue**: Informational Diagnostics

  - Cache statistics, parsed counts, database entry counts
  - Informational details about system state
  - Example: `Write-Host "  [Cache] Content Entries: 126" -ForegroundColor Blue`

- **Magenta**: Special Debug Tracing (Level 3+ only)

  - Function call tracing, module resolution, wrapper function calls
  - Special debug scenarios requiring detailed tracing
  - **Must be conditional on `$debugLevel -ge 3`**
  - Example: `if ($debugLevel -ge 3) { Write-Host "  [fragment-registry.wrapper] Function called" -ForegroundColor Magenta }`

- **DarkGray**: Standard Debug Output (Level 2+)
  - Detailed debug output, verbose information, timing details
  - Performance metrics, cache diagnostics
  - **Must be conditional on appropriate debug level**
  - Example: `if ($debugLevel -ge 2) { Write-Host "  [operation] Timing: ${duration}ms" -ForegroundColor DarkGray }`

##### Color Usage by Message Type

- **Debug output (Level 2+)**: Always use `-ForegroundColor DarkGray` for consistency
- **User-facing messages**: Use appropriate colors (Cyan for info, Yellow for warnings, Green for success, Red for errors)
- **Error display**: Use `-ForegroundColor Red` for error messages (Level 1+)
- **Informational diagnostics**: Use `-ForegroundColor Blue` for cache statistics and system state information
- **Special tracing**: Use `-ForegroundColor Magenta` for function call tracing (Level 3+ only)

##### Conditional Color Coding

Colors can be conditionally applied based on state:

```powershell
# Success/Warning based on value
$color = if ($count -gt 0) { 'Green' } else { 'Yellow' }
Write-Host "  [Cache] Commands found: $count" -ForegroundColor $color

# Progress-based coloring
$progressColor = if ($percent -ge 75) { 'Green' } elseif ($percent -ge 50) { 'Cyan' } elseif ($percent -ge 25) { 'Yellow' } else { 'DarkGray' }
Write-Host "  [operation] Progress: $percent%" -ForegroundColor $progressColor
```

### Complete Example

```powershell
function Invoke-ExampleOperation {
    [CmdletBinding()]
    param(
        [string]$InputPath
    )

    # Parse debug level once at function start
    $debugLevel = 0
    if ($env:PS_PROFILE_DEBUG -and [int]::TryParse($env:PS_PROFILE_DEBUG, [ref]$debugLevel)) {
        # Debug is enabled
    }

    try {
        # Level 1: Basic operation start (minimal output)
        if ($debugLevel -ge 1) {
            Write-Host "  [example.operation] Starting operation on: $InputPath" -ForegroundColor DarkGray
        }

        $startTime = Get-Date

        # Perform operation
        $result = Get-Content -Path $InputPath -ErrorAction Stop

        $duration = ((Get-Date) - $startTime).TotalMilliseconds

        # Level 2: Timing information
        if ($debugLevel -ge 2) {
            Write-Host "  [example.operation] Operation completed in ${duration}ms" -ForegroundColor DarkGray
            # Informational diagnostics (Blue)
            Write-Host "  [example.operation] Processed: $($result.Count) lines" -ForegroundColor Blue
        }

        # Level 3: Detailed breakdown
        if ($debugLevel -ge 3) {
            Write-Host "  [example.operation] Performance breakdown - Read: ${duration}ms, Lines: $($result.Count)" -ForegroundColor DarkGray
            # Special debug tracing (Magenta, Level 3+ only)
            Write-Host "  [example.operation] Function call trace: Get-Content invoked" -ForegroundColor Magenta
        }

        return $result
    }
    catch {
        # Always use structured error handling
        if (Get-Command Write-StructuredError -ErrorAction SilentlyContinue) {
            Write-StructuredError -ErrorRecord $_ -OperationName "example.operation" -Context @{
                input_path = $InputPath
            }
        }
        else {
            # Fallback
            Write-Error "Operation failed: $($_.Exception.Message)"
        }

        # Additional debug details
        if ($debugLevel -ge 2) {
            Write-Host "  [example.operation] Error details: $($_.Exception.GetType().FullName)" -ForegroundColor DarkGray
        }
        if ($debugLevel -ge 3) {
            Write-Host "  [example.operation] Stack trace: $($_.ScriptStackTrace)" -ForegroundColor DarkGray
        }

        throw
    }
}
```

### When to Use Each Level

- **Level 1**: User-facing operational messages, important status updates, basic diagnostics
- **Level 2**: Developer debugging, cache diagnostics, timing analysis, detailed operation context
- **Level 3**: Performance optimization, detailed profiling, sub-operation breakdowns, granular metrics

### Anti-Patterns to Avoid

1. ❌ **Don't use Write-Host for debug messages without checking level**:

   ```powershell
   # ❌ WRONG
   Write-Host "[debug] Cache hit" -ForegroundColor Green

   # ✅ CORRECT
   if ($debugLevel -ge 2) {
       Write-Host "  [cache] Cache hit" -ForegroundColor DarkGray
   }
   ```

2. ❌ **Don't emit debug messages without checking PS_PROFILE_DEBUG**:

   ```powershell
   # ❌ WRONG
   Write-Verbose "[operation] Debug message"

   # ✅ CORRECT
   if ($debugLevel -ge 1) {
       Write-Verbose "[operation] Debug message"
   }
   ```

3. ❌ **Don't use Write-Host for Level 1-2 debug output**:

   ```powershell
   # ❌ WRONG
   if ($debugLevel -ge 1) {
       Write-Host "[operation] Message" -ForegroundColor Cyan  # Wrong color for debug
   }

   # ✅ CORRECT
   if ($debugLevel -ge 2) {
       Write-Host "  [operation] Message" -ForegroundColor DarkGray
   }
   ```

4. ❌ **Don't forget operation tags**:

   ```powershell
   # ❌ WRONG
   Write-Host "  Cache hit" -ForegroundColor DarkGray  # Missing operation tag

   # ✅ CORRECT
   if ($debugLevel -ge 2) {
       Write-Host "  [cache] Cache hit" -ForegroundColor DarkGray
   }
   ```

5. ❌ **Don't use wrong colors for debug output**:

   ```powershell
   # ❌ WRONG
   if ($debugLevel -ge 2) {
       Write-Host "  [operation] Message" -ForegroundColor Green  # Wrong color
   }

   # ✅ CORRECT
   if ($debugLevel -ge 2) {
       Write-Host "  [operation] Message" -ForegroundColor DarkGray  # Standard debug color
   }
   ```

## Configuration

### Environment Variables

- `PS_PROFILE_SERVICE_NAME`: Service name (default: `powershell-profile`)
- `PS_PROFILE_VERSION`: Service version (default: `unknown`)
- `PS_PROFILE_ENV`: Deployment environment (default: `development`)
- `PS_PROFILE_SLOW_THRESHOLD_MS`: Slow request threshold in ms (default: `2000`)
- `PS_PROFILE_VIP_USERS`: Comma-separated list of VIP user IDs
- `PS_PROFILE_SUPPRESS_EVENTS`: Suppress console output (default: unset)
- `PS_PROFILE_DEBUG`: Debug level (0-3, default: `0`)

### Sampling Rates

Default sampling rate for successful operations is **5%** (0.05). Adjust via `-SampleRate` parameter:

```powershell
Write-WideEvent -EventName "operation.name" -Level INFO -SampleRate 0.1  # 10% sampling
```

## Event Structure

All events follow this structure:

```json
{
  "timestamp": "2024-12-20T03:14:23.156Z",
  "event_name": "aws.s3.upload",
  "severity": "INFO",
  "severity_number": 9,
  "service_name": "powershell-profile",
  "service_version": "1.0.0",
  "deployment_environment": "production",
  "duration_ms": 250,
  "outcome": "success",
  "status_code": "OK",
  "context": {
    "user_id": "user_123",
    "bucket": "my-bucket",
    "key": "file.txt",
    "size_bytes": 1024
  },
  "invocation": {
    "script_name": "profile.d/aws.ps1",
    "function_name": "Invoke-AwsS3Upload",
    "line_number": 42,
    "ps_version": "7.4.0",
    "host_name": "ConsoleHost"
  },
  "sampled": false,
  "retention_reason": "sampled"
}
```

For errors, additional fields:

```json
{
  "error": {
    "type": "System.Management.Automation.CommandNotFoundException",
    "message": "The term 'aws' is not recognized",
    "code": -2146233087,
    "stack_trace": "...",
    "source": "profile.d/aws.ps1",
    "line_number": 42
  },
  "status_code": "ERROR",
  "status_message": "The term 'aws' is not recognized"
}
```

## Best Practices

1. **Use descriptive operation names**: Follow `service.operation` pattern (e.g., `aws.s3.upload`, `database.query`)

2. **Include business context**: Add user IDs, request IDs, feature flags, transaction details

3. **Always record errors**: Use `Write-StructuredError` for all exceptions

4. **Wrap expensive operations**: Use `Invoke-WithWideEvent` for operations that should be tracked

5. **Use appropriate log levels**:

   - `DEBUG`: Detailed diagnostic information
   - `INFO`: General informational messages
   - `WARN`: Warning conditions (may indicate problems)
   - `ERROR`: Error conditions (operation failed)
   - `FATAL`: Critical errors (system may be unstable)

6. **Mark critical operations**: Use `-AlwaysKeep` for operations that must never be sampled

7. **Include duration**: Always include `-DurationMs` for performance monitoring

## Examples

### AWS Module Example

```powershell
function Get-AwsResources {
    [CmdletBinding()]
    param(
        [string]$Type
    )

    return Invoke-WithWideEvent -OperationName "aws.resources.list" -Context @{
        resource_type = $Type
        region = $env:AWS_REGION
    } -ScriptBlock {
        if (-not (Test-CachedCommand 'aws')) {
            throw "AWS CLI not found"
        }

        $args = @('resourcegroupstaggingapi', 'get-resources')
        if ($Type) {
            $args += '--resource-type-filters', $Type
        }

        $output = & aws $args 2>&1
        if ($LASTEXITCODE -ne 0) {
            throw "AWS command failed: $output"
        }

        return $output | ConvertFrom-Json
    }
}
```

### Database Module Example

```powershell
function Query-Database {
    [CmdletBinding()]
    param(
        [string]$DatabaseType,
        [string]$Query
    )

    return Invoke-WithWideEvent -OperationName "database.query" -Context @{
        database_type = $DatabaseType
        query = $Query
    } -ScriptBlock {
        switch ($DatabaseType) {
            'PostgreSQL' {
                if (-not (Test-CachedCommand 'psql')) {
                    throw "PostgreSQL client not found"
                }
                & psql -c $Query
            }
            default {
                throw "Unsupported database type: $DatabaseType"
            }
        }
    }
}
```

## References

- [OpenTelemetry Error Handling Specification](https://opentelemetry.io/docs/specs/otel/error-handling/)
- [OpenTelemetry Semantic Conventions](https://opentelemetry.io/docs/specs/semconv/)
- [Wide Events Philosophy](https://loggingsucks.com/)
- [OpenTelemetry .NET Traces - Reporting Exceptions](https://opentelemetry.io/docs/languages/dotnet/traces/reporting-exceptions/)
