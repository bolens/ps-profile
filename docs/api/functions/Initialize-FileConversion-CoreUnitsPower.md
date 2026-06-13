# Initialize-FileConversion-CoreUnitsPower

## Synopsis

Initializes Power unit conversion utility functions.

## Description

Sets up internal conversion functions for power unit conversions. Supports conversions between watts, kilowatts, horsepower, BTU/h, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsPower
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is watts. All conversions go through watts as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/power.ps1
