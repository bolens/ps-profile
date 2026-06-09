# Initialize-FileConversion-MediaColorsNcol

## Synopsis

Initializes NCOL/NCOLA color conversion utility functions.

## Description

Sets up internal conversion functions for NCOL/NCOLA (Natural Color System) color format conversions. Supports converting between NCOL and RGB. This function is called automatically by Initialize-FileConversion-MediaColors.

## Signature

```powershell
Initialize-FileConversion-MediaColorsNcol
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. NCOL uses base colors R (Red), Y (Yellow), G (Green), B (Blue) with hue values 0-100.


## Source

Defined in: ../profile.d/conversion-modules/media/colors/ncol.ps1
