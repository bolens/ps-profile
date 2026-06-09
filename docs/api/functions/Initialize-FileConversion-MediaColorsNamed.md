# Initialize-FileConversion-MediaColorsNamed

## Synopsis

Initializes CSS named colors dictionary.

## Description

Sets up the complete CSS named colors dictionary from CSS Color Module Level 4 specification. This function is called automatically by Ensure-FileConversion-Media.

## Signature

```powershell
Initialize-FileConversion-MediaColorsNamed
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Reference: https://developer.mozilla.org/en-US/docs/Web/CSS/named-color Includes all 16 basic colors plus ~150 extended colors from SVG 1.0 and CSS specifications.


## Source

Defined in: ../profile.d/conversion-modules/media/colors/named.ps1
