# Initialize-FileConversion-CoreEncodingGuid

## Synopsis

Initializes GUID format conversion utility functions.

## Description

Sets up internal conversion functions for GUID (Globally Unique Identifier) format conversions. GUIDs are Windows-specific identifiers, similar to UUIDs but with Windows registry format support. Supports conversions between GUID formats: standard format, hex (no dashes), Base64, Base32, and registry format. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreEncodingGuid
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. GUID format: 8-4-4-4-12 hexadecimal digits (e.g., 550e8400-e29b-41d4-a716-446655440000) Windows registry format: {550e8400-e29b-41d4-a716-446655440000}


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/guid.ps1
