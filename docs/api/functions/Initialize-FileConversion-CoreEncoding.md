# Initialize-FileConversion-CoreEncoding

## Synopsis

Initializes encoding conversion utility functions.

## Description

Sets up internal conversion functions for ASCII, Hexadecimal, Binary, ModHex, Octal, Decimal, Roman Numeral, Base32, and URL/Percent encoding formats. Supports bidirectional conversions between all format combinations. This function is called automatically by Ensure-FileConversion-Data. This is a wrapper that loads and initializes all sub-modules.

## Signature

```powershell
Initialize-FileConversion-CoreEncoding
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. ModHex is a modified hexadecimal encoding used by YubiKey and similar devices. Roman numerals are limited to byte values (1-255) for UTF-8 byte representation. Base32 uses the alphabet A-Z, 2-7 (32 characters) as defined in RFC 4648. URL encoding (percent encoding) follows RFC 3986 specification.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/encoding.ps1
