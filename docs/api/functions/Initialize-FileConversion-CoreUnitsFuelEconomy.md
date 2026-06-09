# Initialize-FileConversion-CoreUnitsFuelEconomy

## Synopsis

Initializes Fuel economy unit conversion utility functions.

## Description

Sets up internal conversion functions for fuel economy unit conversions. Supports conversions between mpg (US/UK), L/100km, and km/L. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsFuelEconomy
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is liters per 100 kilometers. Inverse units require special handling.


## Source

Defined in: ../profile.d/conversion-modules/data/units/fueleconomy.ps1
