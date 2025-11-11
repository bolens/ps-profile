# Invoke-HttpRequestWithRetry

## Synopsis

Makes HTTP requests with retry logic and timeout handling.

## Description

Enhanced HTTP client with automatic retry for transient network failures and configurable timeouts.

## Signature

```powershell
Invoke-HttpRequestWithRetry
```

## Parameters

### -Uri

The URI to request.

### -Method

HTTP method. Default is GET.

### -TimeoutSeconds

Request timeout in seconds. Default is 30.

### -MaxRetries

Maximum retry attempts. Default is 3.


## Examples

No examples provided.

## Source

Defined in: profile.d\71-network-utils.ps1
