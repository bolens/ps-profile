# Parse-ToonValue

## Synopsis

Parses a single TOON value string into a PowerShell object.

## Description

Converts a TOON value string (number, string, boolean, null) into the appropriate PowerShell type. This is an internal helper function used by Parse-ToonLines.

## Signature

```powershell
Parse-ToonValue
```

## Parameters

### -Value

The TOON value string to parse.


## Outputs

The parsed value as a PowerShell object (string, int, double, bool, or null). .EXAMPLE Parse-ToonValue


## Examples

### Example 1

`powershell
Parse-ToonValue
``

## Source

Defined in: ../profile.d/conversion-modules/helpers/helpers-toon.ps1
