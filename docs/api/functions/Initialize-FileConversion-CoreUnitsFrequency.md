# Initialize-FileConversion-CoreUnitsFrequency

## Synopsis

Initializes Frequency unit conversion utility functions.

## Description

Sets up internal conversion functions for frequency and rotational speed conversions. Supports conversions between hertz, kilohertz, megahertz, rpm, rad/s, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsFrequency
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is hertz. All conversions go through Hz as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/frequency.ps1
