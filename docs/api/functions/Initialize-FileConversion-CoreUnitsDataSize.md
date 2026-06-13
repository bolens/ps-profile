# Initialize-FileConversion-CoreUnitsDataSize

## Synopsis

Initializes Data Size unit conversion utility functions.

## Description

Sets up internal conversion functions for data size unit conversions. Supports conversions between bytes, kilobytes, megabytes, gigabytes, terabytes, petabytes, and exabytes. Supports both binary (1024-based) and decimal (1000-based) units. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsDataSize
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Binary units (KiB, MiB, GiB, etc.) use 1024 as the base multiplier. Decimal units (KB, MB, GB, etc.) use 1000 as the base multiplier. Default behavior uses binary units (1024-based) for consistency with most systems.


## Source

Defined in: ../profile.d/conversion-modules/data/units/datasize.ps1
