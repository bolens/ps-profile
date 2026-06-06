# Initialize-FileConversion-CoreUnitsDensity

## Synopsis

Initializes Density unit conversion utility functions.

## Description

Sets up internal conversion functions for density unit conversions. Supports conversions between kg/m³, g/cm³, lb/ft³, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsDensity
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is kilograms per cubic meter. All conversions go through kg/m³ as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/density.ps1
