# Initialize-FileConversion-CoreUnitsTemperature

## Synopsis

Initializes Temperature unit conversion utility functions.

## Description

Sets up internal conversion functions for temperature unit conversions. Supports conversions between Celsius, Fahrenheit, and Kelvin. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsTemperature
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Temperature conversions require special handling as they have different zero points. Base unit is Kelvin for absolute temperature, but conversions are direct between all three scales.


## Source

Defined in: ../profile.d/conversion-modules/data/units/temperature.ps1
