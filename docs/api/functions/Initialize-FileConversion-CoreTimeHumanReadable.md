# Initialize-FileConversion-CoreTimeHumanReadable

## Synopsis

Initializes Human-readable date/time conversion utility functions.

## Description

Sets up internal conversion functions for human-readable date/time format conversions. Supports conversions between natural language dates and DateTime objects, Unix timestamps, ISO 8601, and RFC 3339. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreTimeHumanReadable
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Supports natural language date expressions like "tomorrow", "next week", "2 days ago", "in 3 hours", etc.


## Source

Defined in: ../profile.d/conversion-modules/data/time/human-readable.ps1
