# Initialize-FileConversion-CoreUnitsTime

## Synopsis

Initializes Time duration unit conversion utility functions.

## Description

Sets up internal conversion functions for time duration unit conversions. Supports conversions between nanoseconds, microseconds, milliseconds, seconds, minutes, hours, days, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsTime
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is seconds. All conversions go through seconds as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/time.ps1
