# Initialize-FileConversion-CoreUnitsDataRate

## Synopsis

Initializes Data rate unit conversion utility functions.

## Description

Sets up internal conversion functions for data rate / bandwidth conversions. Supports conversions between bps, Kbps, Mbps, Gbps, B/s, and related units. This function is called automatically by Ensure-FileConversion-Data.

## Signature

```powershell
Initialize-FileConversion-CoreUnitsDataRate
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Base unit is bits per second. Network rates use decimal (1000-based) multipliers by default.


## Source

Defined in: ../profile.d/conversion-modules/data/units/datarate.ps1
