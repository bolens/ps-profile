# Initialize-FileConversion-CoreUnitsLength

## Synopsis

Initializes Length unit conversion utility functions.

## Description

Sets up internal conversion functions for length unit conversions. Supports conversions between meters, feet, inches, miles, kilometers, centimeters, millimeters, yards, nautical miles, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsLength
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is meters. All conversions go through meters as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/length.ps1
