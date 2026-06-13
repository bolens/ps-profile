# Initialize-FileConversion-CoreUnitsArea

## Synopsis

Initializes Area unit conversion utility functions.

## Description

Sets up internal conversion functions for area unit conversions. Supports conversions between square meters, square feet, square inches, acres, hectares, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsArea
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is square meters. All conversions go through m² as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/area.ps1
