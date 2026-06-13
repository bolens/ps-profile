# Initialize-FileConversion-CoreEncodingBase122

## Synopsis

Initializes Base122 encoding conversion utility functions.

## Description

Sets up internal conversion functions for Base122 encoding format. Base122 uses 122 printable ASCII characters for URL-safe binary encoding. More efficient than Base64 while remaining URL-safe. Supports bidirectional conversions between Base122 and other formats. This function is called automatically by Initialize-FileConversion-CoreEncoding.

## Signature

```powershell
Initialize-FileConversion-CoreEncodingBase122
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base122 encoding works on variable-length encoding without padding. Uses 122 characters: all printable ASCII except some problematic URL characters.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base122.ps1
