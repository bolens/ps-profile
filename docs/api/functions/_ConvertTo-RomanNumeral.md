# _ConvertTo-RomanNumeral

## Synopsis

Initializes Roman numeral encoding conversion utility functions.

## Description

Sets up internal conversion functions for Roman numeral encoding format. Supports bidirectional conversions between Roman numerals and byte values (1-255). This function is called automatically by Initialize-FileConversion-CoreEncoding.

## Signature

```powershell
_ConvertTo-RomanNumeral [Int32]$Number
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Roman numerals are limited to byte values (1-255) for UTF-8 byte representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/roman.ps1
