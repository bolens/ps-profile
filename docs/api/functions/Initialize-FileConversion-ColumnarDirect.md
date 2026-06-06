# Initialize-FileConversion-ColumnarDirect

## Synopsis

Initializes direct columnar format conversion utility functions.

## Description

Sets up internal conversion functions for direct conversions between Parquet and Arrow. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-ColumnarDirect
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Node.js, the parquetjs package, and the apache-arrow package to be installed.


## Source

Defined in: ../profile.d/conversion-modules/data/columnar/columnar-direct.ps1
