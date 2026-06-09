# ConvertFrom-DurationToTimeSpan

## Synopsis

Converts a human-readable duration string to a TimeSpan object.

## Description

Converts natural language duration expressions to TimeSpan objects. Supports expressions like "2 hours", "30 minutes", "1 day 3 hours 15 minutes", etc.

## Signature

```powershell
ConvertFrom-DurationToTimeSpan
```

## Parameters

### -DurationString

The human-readable duration string to convert.


## Outputs

System.TimeSpan Returns a TimeSpan object representing the duration.


## Examples

### Example 1

```powershell
"2 hours" | ConvertFrom-DurationToTimeSpan
```

Converts "2 hours" to a TimeSpan object.

### Example 2

```powershell
"1 day 3 hours 15 minutes" | ConvertFrom-DurationToTimeSpan
```

Converts a complex duration to a TimeSpan object.

### Example 3

```powershell
"3600" | ConvertFrom-DurationToTimeSpan
```

Converts a number (assumed to be seconds) to a TimeSpan object.

## Aliases

This function has the following aliases:

- `duration-to-timespan` - Converts a human-readable duration string to a TimeSpan object.


## Source

Defined in: ../profile.d/conversion-modules/data/time/duration.ps1
