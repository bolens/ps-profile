# Initialize-FileConversion-CoreTimeDuration

## Synopsis

Initializes Duration/TimeSpan conversion utility functions.

## Description

Sets up internal conversion functions for duration/time span conversions. Supports conversions between human-readable durations and TimeSpan objects, seconds, milliseconds, etc. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreTimeDuration
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Supports duration expressions like "2 hours", "30 minutes", "1 day 3 hours", etc.


## Source

Defined in: ../profile.d/conversion-modules/data/time/duration.ps1
