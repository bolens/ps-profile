# Initialize-FileConversion-CoreUnitsAcceleration

## Synopsis

Initializes Acceleration unit conversion utility functions.

## Description

Sets up internal conversion functions for acceleration unit conversions. Supports conversions between m/s², ft/s², standard gravity, and gal. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsAcceleration
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is meters per second squared. All conversions go through m/s² as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/acceleration.ps1
