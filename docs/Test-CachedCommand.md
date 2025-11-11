# Test-CachedCommand

## Synopsis

Tests for command availability with caching and TTL.

## Description

Lightweight cached command testing used by profile fragments to avoid repeated Get-Command calls. Results are cached in script scope for performance. Cache entries expire after 5 minutes to handle cases where commands are installed after profile load.

## Signature

```powershell
Test-CachedCommand
```

## Parameters

### -Name

The name of the command to test.

### -CacheTTLMinutes

Optional. Cache time-to-live in minutes. Default is 5 minutes.


## Examples

### Example 1

`powershell
if (Test-CachedCommand 'docker') { # configure docker helpers }
``

## Source

Defined in: profile.d\00-bootstrap.ps1
