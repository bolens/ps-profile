# Initialize-FileConversion-CoreCompressionLz4

## Synopsis

Initializes LZ4 compression format conversion utility functions.

## Description

Sets up internal conversion functions for LZ4 compression/decompression. LZ4 is a fast compression algorithm with high compression and decompression speeds. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreCompressionLz4
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires lz4 command-line tool to be installed and available in PATH. Install hint resolved via Get-ConversionToolMissingMessage -ToolName lz4.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/lz4.ps1
