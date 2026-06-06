# Initialize-FileConversion-CoreUnitsTorque

## Synopsis

Initializes Torque unit conversion utility functions.

## Description

Sets up internal conversion functions for torque unit conversions. Supports conversions between newton-meters, pound-feet, pound-inches, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsTorque
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is newton-meters. All conversions go through N·m as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/torque.ps1
