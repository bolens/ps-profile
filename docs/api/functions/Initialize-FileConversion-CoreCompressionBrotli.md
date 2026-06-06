# Initialize-FileConversion-CoreCompressionBrotli

## Synopsis

Initializes Brotli compression format conversion utility functions.

## Description

Sets up internal conversion functions for Brotli compression/decompression. Brotli is a modern compression algorithm developed by Google. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreCompressionBrotli
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Uses .NET System.IO.Compression.BrotliStream (available in .NET Core 2.1+ and .NET 5+). For PowerShell 5.1, BrotliStream may not be available.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/brotli.ps1
