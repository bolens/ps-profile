# Initialize-FileConversion-CoreEncodingUuid

## Synopsis

Initializes UUID format conversion utility functions.

## Description

Sets up internal conversion functions for UUID (Universally Unique Identifier) format conversions. Supports conversions between UUID formats: standard format, hex (no dashes), Base64, Base32, and binary. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreEncodingUuid
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. UUID format: 8-4-4-4-12 hexadecimal digits (e.g., 550e8400-e29b-41d4-a716-446655440000)


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/uuid.ps1
