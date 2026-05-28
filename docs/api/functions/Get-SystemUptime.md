# Get-SystemUptime

## Synopsis

Shows system uptime.

## Description

Calculates and displays the time elapsed since the system was last booted. On Windows uses Win32_OperatingSystem; on Linux reads /proc/uptime; on macOS uses sysctl.

## Signature

```powershell
Get-SystemUptime
```

## Parameters

No parameters.

## Examples

No examples provided.

## Aliases

This function has the following aliases:

- `uptime` - Shows system uptime.


## Source

Defined in: ../profile.d/system-info.ps1
