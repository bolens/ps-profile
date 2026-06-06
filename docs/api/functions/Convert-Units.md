# Convert-Units

## Synopsis

Converts values between different units.

## Description

Converts values between file size units (B, KB, MB, GB, TB, PB, bits) and time units (ns through years). Delegates to Convert-DataSize and Convert-Duration when the file conversion modules are loaded.

## Signature

```powershell
Convert-Units
```

## Parameters

### -Value

The numeric value to convert.

### -FromUnit

The unit of the input value (e.g., "MB", "hours").

### -ToUnit

The unit to convert to (e.g., "KB", "minutes").


## Outputs

PSCustomObject Object containing Value, Unit, OriginalValue, and OriginalUnit properties.


## Examples

### Example 1

`powershell
Convert-Units -Value 1024 -FromUnit "KB" -ToUnit "MB"
    Converts 1024 KB to MB (1 MB).
``

### Example 2

`powershell
Convert-Units -Value 3600 -FromUnit "seconds" -ToUnit "hours"
    Converts 3600 seconds to hours (1 hour).
``

## Aliases

This function has the following aliases:

- `unit-convert` - Converts values between different units.


## Source

Defined in: ../profile.d/dev-tools-modules/data/units.ps1
