# Resolve-HostWithRetry

## Synopsis

Resolves hostnames with retry logic.

## Description

DNS resolution with automatic retry for transient DNS failures.

## Signature

```powershell
Resolve-HostWithRetry
```

## Parameters

### -HostName

The hostname to resolve.

### -TimeoutSeconds

Timeout for DNS resolution. Default is 10.


## Examples

### Example 1

`powershell
Resolve-HostWithRetry
``

## Source

Defined in: ../profile.d/utilities-modules/network/utilities-network-advanced.ps1
