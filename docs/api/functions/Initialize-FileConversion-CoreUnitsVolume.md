# Initialize-FileConversion-CoreUnitsVolume

## Synopsis

Initializes Volume unit conversion utility functions.

## Description

Sets up internal conversion functions for volume unit conversions. Supports conversions between liters, gallons, fluid ounces, cubic meters, cubic feet, cubic inches, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsVolume
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is liters. All conversions go through liters as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/volume.ps1
