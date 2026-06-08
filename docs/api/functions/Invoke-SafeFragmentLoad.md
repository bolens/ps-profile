# Invoke-SafeFragmentLoad

## Synopsis

Loads profile fragments with enhanced error handling and retry logic.

## Description

Wraps fragment loading with retry mechanisms and better error reporting. Attempts to recover from transient failures.

## Signature

```powershell
Invoke-SafeFragmentLoad
```

## Parameters

### -FragmentPath

Path to the fragment file to load.

### -FragmentName

Name of the fragment for logging.

### -MaxRetries

Maximum number of retry attempts.


## Examples

### Example 1

`powershell
Invoke-SafeFragmentLoad
``

## Source

Defined in: ../profile.d/diagnostics-modules/core/diagnostics-error-handling.ps1
