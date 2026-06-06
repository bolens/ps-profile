# Initialize-FileConversion-BinaryProtocolIceberg

## Synopsis

Initializes Apache Iceberg format conversion utility functions.

## Description

Sets up internal conversion functions for Apache Iceberg format conversions. Iceberg is an open table format for huge analytic tables. Supports bidirectional conversions between Iceberg tables and JSON, and conversions to Parquet. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-BinaryProtocolIceberg
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Python with pyiceberg package to be installed.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-protocol-iceberg.ps1
