# Initialize-FileConversion-CoreTimeTimezone

## Synopsis

Initializes Timezone conversion utility functions.

## Description

Sets up internal conversion functions for timezone conversions. Supports conversions between different timezones and standard date/time formats. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreTimeTimezone
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Uses .NET TimeZoneInfo for timezone conversions.


## Source

Defined in: ../profile.d/conversion-modules/data/time/timezone.ps1
