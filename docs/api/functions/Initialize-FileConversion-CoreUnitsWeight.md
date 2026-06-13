# Initialize-FileConversion-CoreUnitsWeight

## Synopsis

Initializes Weight/Mass unit conversion utility functions.

## Description

Sets up internal conversion functions for weight/mass unit conversions. Supports conversions between kilograms, pounds, ounces, grams, tons, stones, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsWeight
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is kilograms. All conversions go through kilograms as an intermediate step.


## Source

Defined in: ../profile.d/conversion-modules/data/units/weight.ps1
