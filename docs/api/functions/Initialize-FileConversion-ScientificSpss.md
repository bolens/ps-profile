# Initialize-FileConversion-ScientificSpss

## Synopsis

Initializes SPSS format conversion utility functions.

## Description

Sets up internal conversion functions for SPSS data formats (.sav, .zsav, .por). SPSS is a statistical software package. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-ScientificSpss
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Python with pandas/polars and pyreadstat packages to be installed. Alternatively, requires SPSS software to be installed for native conversions.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-spss.ps1
