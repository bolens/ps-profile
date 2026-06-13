# _Convert-CmykToRgb

## Synopsis

Initializes CMYK/CMYKA color conversion utility functions.

## Description

Sets up internal conversion functions for CMYK/CMYKA color format conversions. Supports converting between CMYK and RGB. This function is called automatically by Ensure-FileConversion-Media.

## Signature

```powershell
_Convert-CmykToRgb [Double]$Cyan, [Double]$Magenta, [Double]$Yellow, [Double]$Key
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. CMYK conversions follow standard printing color model specifications.


## Source

Defined in: ../profile.d/conversion-modules/media/colors/cmyk.ps1
