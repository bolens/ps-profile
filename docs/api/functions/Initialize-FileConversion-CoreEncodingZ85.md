# Initialize-FileConversion-CoreEncodingZ85

## Synopsis

Initializes Z85 encoding conversion utility functions.

## Description

Sets up internal conversion functions for Z85 encoding format. Z85 is ZeroMQ's variant of Base85, using a URL-safe and human-readable alphabet. Uses the alphabet: 0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ.-:+=^!/*?&<>()[]{}@%$# The encoding works on 4-byte groups converted to 5 Z85 characters. Supports bidirectional conversions between Z85 and other formats. This function is called automatically by Initialize-FileConversion-CoreEncoding.

## Signature

```powershell
Initialize-FileConversion-CoreEncodingZ85
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Z85 encoding works on 4-byte groups with padding if needed. Unlike Base85/Ascii85, Z85 does not use 'z' compression for zero bytes. Reference: https://rfc.zeromq.org/spec/32/


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/z85.ps1
