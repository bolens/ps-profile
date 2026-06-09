# Initialize-FileConversion-NetworkMimeTypes

## Synopsis

Initializes MIME types parsing and conversion utility functions.

## Description

Sets up internal conversion functions for MIME type parsing and conversion. Supports parsing MIME types and converting between MIME type format and components, file extensions, etc. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-NetworkMimeTypes
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. MIME type format: type/subtype; parameter=value Examples: text/plain, application/json, image/png; charset=utf-8


## Source

Defined in: ../profile.d/conversion-modules/data/network/network-mime-types.ps1
