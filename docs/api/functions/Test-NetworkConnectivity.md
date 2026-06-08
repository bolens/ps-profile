# Test-NetworkConnectivity

## Synopsis

Tests network connectivity with retry logic.

## Description

Enhanced version of network connectivity testing with automatic retry for transient network issues.

## Signature

```powershell
Test-NetworkConnectivity
```

## Parameters

### -Target

The target host or IP to test connectivity to.

### -Port

The port to test. Default is 80.

### -TimeoutSeconds

Timeout for each connectivity test. Default is 5.


## Examples

### Example 1

```powershell
Test-NetworkConnectivity -Target 'value'
```

## Source

Defined in: ../profile.d/utilities-modules/network/utilities-network-advanced.ps1
