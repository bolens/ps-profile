# Initialize-FileConversion-CoreTimeRfc3339

## Synopsis

Initializes RFC 3339 date/time conversion utility functions.

## Description

Sets up internal conversion functions for RFC 3339 date/time format conversions. RFC 3339 is a profile of ISO 8601 with specific formatting requirements. Supports conversions between RFC 3339 and DateTime objects, Unix timestamps, ISO 8601, and human-readable formats. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreTimeRfc3339
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. RFC 3339 format: yyyy-MM-ddTHH:mm:ss[.fff]Z or yyyy-MM-ddTHH:mm:ss[.fff]+HH:mm RFC 3339 requires timezone information (Z for UTC or +/-HH:mm offset).


## Source

Defined in: ../profile.d/conversion-modules/data/time/rfc3339.ps1
