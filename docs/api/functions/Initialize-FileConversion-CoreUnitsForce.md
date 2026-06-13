# Initialize-FileConversion-CoreUnitsForce

## Synopsis

Initializes Force unit conversion utility functions.

## Description

Sets up internal conversion functions for force unit conversions. Supports conversions between newtons, pound-force, kilogram-force, dynes, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsForce
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is newtons. All conversions go through newtons as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/force.ps1
