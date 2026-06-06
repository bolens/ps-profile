# Initialize-FileConversion-CoreUnitsAngle

## Synopsis

Initializes Angle unit conversion utility functions.

## Description

Sets up internal conversion functions for angle unit conversions. Supports conversions between degrees, radians, gradians, and turns. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsAngle
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is radians. All conversions go through radians as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/angle.ps1
