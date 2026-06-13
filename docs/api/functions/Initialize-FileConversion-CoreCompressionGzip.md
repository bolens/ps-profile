# Initialize-FileConversion-CoreCompressionGzip

## Synopsis

Initializes Gzip/Zlib compression format conversion utility functions.

## Description

Sets up internal conversion functions for Gzip and Zlib compression/decompression. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreCompressionGzip
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Uses .NET System.IO.Compression classes for compression/decompression.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/gzip.ps1
