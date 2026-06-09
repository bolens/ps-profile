# Initialize-FileConversion-CoreUnitsTypography

## Synopsis

Initializes Typography unit conversion utility functions.

## Description

Sets up internal conversion functions for typography and print unit conversions. Supports conversions between points, picas, pixels (at a given DPI), inches, millimeters, and more. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsTypography
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is meters. Pixel conversions require a -Dpi parameter (default 96).


## Source

Defined in: ../profile.d/conversion-modules/data/units/typography.ps1
