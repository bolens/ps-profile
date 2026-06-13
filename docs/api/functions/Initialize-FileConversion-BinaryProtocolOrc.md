# Initialize-FileConversion-BinaryProtocolOrc

## Synopsis

Initializes Apache ORC format conversion utility functions.

## Description

Sets up internal conversion functions for Apache ORC (Optimized Row Columnar) format. ORC is a columnar storage format optimized for reading, writing, and processing data. Supports bidirectional conversions between ORC and JSON, CSV, and Parquet formats. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-BinaryProtocolOrc
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Python with pyarrow package to be installed.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-orc.ps1
