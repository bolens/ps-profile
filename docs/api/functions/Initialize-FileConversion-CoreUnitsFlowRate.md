# Initialize-FileConversion-CoreUnitsFlowRate

## Synopsis

Initializes Flow rate unit conversion utility functions.

## Description

Sets up internal conversion functions for volumetric flow rate conversions. Supports conversions between L/s, L/min, gpm, cfm, m³/h, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsFlowRate
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is liters per second. All conversions go through L/s as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/flowrate.ps1
