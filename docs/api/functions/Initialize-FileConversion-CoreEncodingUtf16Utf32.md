# Initialize-FileConversion-CoreEncodingUtf16Utf32

## Synopsis

Initializes UTF-16/UTF-32 encoding conversion utility functions.

## Description

Sets up internal conversion functions for UTF-16 and UTF-32 encoding formats. UTF-16 uses 16-bit code units (2 bytes per character, or 4 bytes for surrogate pairs). UTF-32 uses 32-bit code units (4 bytes per character). Supports both little-endian (LE) and big-endian (BE) byte orders. Supports bidirectional conversions between UTF-16/UTF-32 and other formats. This function is called automatically by Initialize-FileConversion-CoreEncoding.

## Signature

```powershell
Initialize-FileConversion-CoreEncodingUtf16Utf32
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. UTF-16 and UTF-32 encodings use BOM (Byte Order Mark) to indicate endianness. Default behavior uses little-endian (Windows standard). Reference: Unicode Standard, RFC 2781 (UTF-16)


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/utf16-utf32.ps1
