# Initialize-FileConversion-CoreUnitsEnergy

## Synopsis

Initializes Energy unit conversion utility functions.

## Description

Sets up internal conversion functions for energy unit conversions. Supports conversions between joules, calories, kilowatt-hours, BTUs, electronvolts, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsEnergy
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is joules. All conversions go through joules as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/energy.ps1
