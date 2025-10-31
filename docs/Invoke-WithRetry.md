# Invoke-WithRetry

## Synopsis

Executes a network operation with retry logic and timeout handling.

## Description

Wraps network operations with automatic retry on transient failures
    and configurable timeouts to improve reliability.

## Signature

```powershell
Invoke-WithRetry
```

## Parameters

### -ScriptBlock

The operation to execute.

### -MaxRetries

Maximum number of retry attempts. Default is 3.

### -TimeoutSeconds

Timeout in seconds for each attempt. Default is 30.


## Examples

No examples provided.

## Source

Defined in: profile.d\71-network-utils.ps1
