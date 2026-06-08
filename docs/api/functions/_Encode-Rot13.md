# _Encode-Rot13

## Synopsis

Initializes ROT13/ROT47 cipher encoding conversion utility functions.

## Description

Sets up internal conversion functions for ROT13 and ROT47 cipher encoding formats. ROT13 rotates letters by 13 positions (A-Z, a-z). ROT47 rotates all printable ASCII characters (33-126) by 47 positions. Supports bidirectional conversions (encoding and decoding are the same operation). This function is called automatically by Initialize-FileConversion-CoreEncoding.

## Signature

```powershell
_Encode-Rot13 [String]$Text
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. ROT13 and ROT47 are self-inverse ciphers (applying twice returns original text).


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/rot.ps1
