# Initialize-FileConversion-ScientificSas

## Synopsis

Initializes SAS format conversion utility functions.

## Description

Sets up internal conversion functions for SAS data formats (.sas7bdat, .xpt). SAS is a statistical software package. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-ScientificSas
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Python with pandas/polars and pyreadstat packages to be installed. Alternatively, requires SAS software to be installed for native conversions.


## Source

Defined in: ../profile.d/conversion-modules/data/scientific/scientific-sas.ps1
