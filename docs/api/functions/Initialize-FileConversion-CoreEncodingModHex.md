# Initialize-FileConversion-CoreEncodingModHex

## Synopsis

Initializes ModHex encoding conversion utility functions.

## Description

Sets up internal conversion functions for ModHex (modified hexadecimal) encoding format. ModHex is used by YubiKey and similar devices. Supports bidirectional conversions between ModHex and other formats. This function is called automatically by Initialize-FileConversion-CoreEncoding.

## Signature

```powershell
Initialize-FileConversion-CoreEncodingModHex
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. ModHex uses characters: c, b, d, e, f, g, h, i, j, k, l, n, r, t, u, v instead of 0-9, A-F.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/modhex.ps1
