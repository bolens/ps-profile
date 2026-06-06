# Initialize-FileConversion-DigestHashFormat

## Synopsis

Initializes hash format conversion utility functions.

## Description

Sets up internal conversion functions for converting hash values between different representations. Supports conversions between Hex, Base64, and Base32 formats for hash/digest values. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-DigestHashFormat
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Hash format conversions are useful for converting between different hash representations (e.g., converting a hex hash to Base64 or Base32 format).


## Source

Defined in: ../profile.d/conversion-modules/data/digest/digest-hash-format.ps1
