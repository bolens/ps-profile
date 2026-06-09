# Initialize-FileConversion-CoreUnitsPressure

## Synopsis

Initializes Pressure unit conversion utility functions.

## Description

Sets up internal conversion functions for pressure unit conversions. Supports conversions between pascals, psi, bar, atmospheres, torr, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsPressure
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is pascals. All conversions go through pascals as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/pressure.ps1
