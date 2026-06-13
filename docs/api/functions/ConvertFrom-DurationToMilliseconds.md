# ConvertFrom-DurationToMilliseconds

## Synopsis

Converts a TimeSpan object to a human-readable duration string.

## Description

Converts a TimeSpan object to a human-readable duration string.

## Signature

```powershell
ConvertFrom-DurationToMilliseconds
```

## Parameters

### -TimeSpan

The TimeSpan object to convert.

### -Format

The format to use: 'long' (default) for "2 days 3 hours", 'short' for "2d 3h", 'iso8601' for "P2DT3H", or a custom format string.


## Outputs

System.String Returns a human-readable duration string.


## Examples

### Example 1

```powershell
New-TimeSpan -Days 2 -Hours 3 -Minutes 15 | ConvertTo-DurationFromTimeSpan
```

Converts a TimeSpan to "2 days 3 hours 15 minutes".

### Example 2

```powershell
New-TimeSpan -Hours 2 | ConvertTo-DurationFromTimeSpan -Format 'short'
```

Converts to "2h".

### Example 3

```powershell
New-TimeSpan -Days 1 -Hours 2 -Minutes 3 | ConvertTo-DurationFromTimeSpan -Format 'iso8601'
```

Converts to "P1DT2H3M" (ISO 8601 duration format).

## Aliases

This function has the following aliases:

- `duration-to-milliseconds` - Converts a TimeSpan object to a human-readable duration string.


## Source

Defined in: ../profile.d/conversion-modules/data/time/duration.ps1
