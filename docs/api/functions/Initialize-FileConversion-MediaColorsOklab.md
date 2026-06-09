# Initialize-FileConversion-MediaColorsOklab

## Synopsis

Initializes OKLAB/OKLABa color conversion utility functions.

## Description

Sets up internal conversion functions for OKLAB/OKLABa color format conversions. Supports converting between OKLAB and RGB via linear RGB intermediate color space. This function is called automatically by Ensure-FileConversion-Media.

## Signature

```powershell
Initialize-FileConversion-MediaColorsOklab
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. OKLAB conversions follow CSS Color Module Level 4 specifications. OKLAB is an improved perceptually uniform color space, better than traditional LAB. Uses sRGB color space.


## Source

Defined in: ../profile.d/conversion-modules/media/colors/oklab.ps1
