# Write-ProfileError

## Synopsis

Logs errors with enhanced context and formatting.

## Description

Provides comprehensive error logging with timestamps, context, and suggestions. Logs to both console (when debugging) and file for persistent debugging.

## Signature

```powershell
Write-ProfileError
```

## Parameters

### -ErrorRecord

The error record to log.

### -Context

Additional context about where the error occurred.

### -Category

Error category for better organization.


## Examples

### Example 1

`powershell
Write-ProfileError
``

## Source

Defined in: ../profile.d/diagnostics-modules/core/diagnostics-error-handling.ps1
