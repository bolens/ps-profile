# Initialize-FileConversion-CoreCompressionZstd

## Synopsis

Initializes Zstandard (zstd) compression format conversion utility functions.

## Description

Sets up internal conversion functions for Zstandard (zstd) compression/decompression. Zstandard is a fast compression algorithm developed by Facebook. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreCompressionZstd
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires zstd command-line tool to be installed and available in PATH. Install hint resolved via Get-ConversionToolMissingMessage -ToolName zstd.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/zstd.ps1
