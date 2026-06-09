# Initialize-FileConversion-CoreEncodingBase91

## Synopsis

Initializes Base91 encoding conversion utility functions.

## Description

Sets up internal conversion functions for Base91 encoding format. Base91 uses 91 printable ASCII characters (33-126, excluding some characters). More efficient than Base64, providing better compression ratio. Supports bidirectional conversions between Base91 and other formats. This function is called automatically by Initialize-FileConversion-CoreEncoding.

## Signature

```powershell
Initialize-FileConversion-CoreEncodingBase91
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base91 encoding works on variable-length encoding without padding. Uses the standard Base91 alphabet: A-Z, a-z, 0-9, and special characters.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base91.ps1
