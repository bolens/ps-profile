# Initialize-FileConversion-BinaryToText

## Synopsis

Initializes binary format conversion utility functions.

## Description

Sets up internal conversion functions for binary-to-text conversions from BSON, MessagePack, and CBOR to CSV and YAML. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-BinaryToText
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Requires Node.js and respective npm packages for each format.


## Source

Defined in: ../profile.d/conversion-modules/data/binary/binary-to-text.ps1
