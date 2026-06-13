# Initialize-FileConversion-CoreTimeIso8601

## Synopsis

Initializes ISO 8601 date/time conversion utility functions.

## Description

Sets up internal conversion functions for ISO 8601 date/time format conversions. Supports conversions between ISO 8601 and DateTime objects, Unix timestamps, RFC 3339, and human-readable formats. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreTimeIso8601
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. ISO 8601 is an international standard for date and time representation. Supports various ISO 8601 formats including with/without timezone, with/without milliseconds.


## Source

Defined in: ../profile.d/conversion-modules/data/time/iso8601.ps1
