# Initialize-FileConversion-CoreUnitsSpeed

## Synopsis

Initializes Speed unit conversion utility functions.

## Description

Sets up internal conversion functions for speed unit conversions. Supports conversions between meters per second, kilometers per hour, miles per hour, knots, feet per second, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsSpeed
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is meters per second. All conversions go through m/s as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/speed.ps1
