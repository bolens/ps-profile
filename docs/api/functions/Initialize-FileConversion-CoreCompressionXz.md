# Initialize-FileConversion-CoreCompressionXz

## Synopsis

Initializes XZ/LZMA compression format conversion utility functions.

## Description

Sets up internal conversion functions for XZ and LZMA compression/decompression. XZ is a compression format using the LZMA2 algorithm, providing high compression ratios. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreCompressionXz
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires xz command-line tool to be installed and available in PATH. Install hint resolved via Get-ConversionToolMissingMessage -ToolName xz.


## Source

Defined in: ../profile.d/conversion-modules/data/compression/xz.ps1
