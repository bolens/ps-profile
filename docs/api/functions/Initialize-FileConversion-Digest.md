# Initialize-FileConversion-Digest

## Synopsis

Initializes hash and digest format conversion utility functions.

## Description

Sets up internal conversion functions for hash and digest formats. Supports hash format conversions (Hex ↔ Base64 ↔ Base32) and checksum calculations (CRC32, Adler32). This function is called automatically by Ensure-FileConversion-Data. This is a wrapper that loads and initializes all digest sub-modules.

## Signature

```powershell
Initialize-FileConversion-Digest
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Digest formats include: - Hash format conversions (Hex, Base64, Base32) - Checksum calculations (CRC32, Adler32)


## Source

Defined in: ../profile.d/conversion-modules/data/digest/digest.ps1
