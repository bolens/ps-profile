# Initialize-FileConversion-CoreTimeUnix

## Synopsis

Initializes Unix Timestamp conversion utility functions.

## Description

Sets up internal conversion functions for Unix Timestamp (epoch time) conversions. Supports conversions between Unix timestamps and DateTime objects, ISO 8601, RFC 3339, and human-readable formats. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreTimeUnix
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Unix timestamps represent seconds since January 1, 1970 UTC (Unix epoch). Supports both integer and floating-point timestamps (with milliseconds).


## Source

Defined in: ../profile.d/conversion-modules/data/time/unix.ps1
