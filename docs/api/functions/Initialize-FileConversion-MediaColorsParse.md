# Initialize-FileConversion-MediaColorsParse

## Synopsis

Initializes color parsing utility functions.

## Description

Sets up the main color parsing function that routes to format-specific parsers. Supports parsing RGB, RGBA, HEX, HSL, HSLA, HWB, HWBA, CMYK, CMYKA, NCOL, NCOLA, LAB, LABa, OKLAB, OKLABa, LCH, LCHa, OKLCH, OKLCHa, and named colors. This function is called automatically by Initialize-FileConversion-MediaColors.

## Signature

```powershell
Initialize-FileConversion-MediaColorsParse
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly.


## Source

Defined in: ../profile.d/conversion-modules/media/colors/parse.ps1
