# ConvertFrom-GuidToHex

## Synopsis

Converts a GUID to hexadecimal format (no dashes).

## Description

Converts a GUID string to hexadecimal format without dashes or braces.

## Signature

```powershell
ConvertFrom-GuidToHex [String]$Guid
```

## Parameters

### -Guid

**Type:** [String]

The GUID string to convert (e.g., "550e8400-e29b-41d4-a716-446655440000" or "{550e8400-e29b-41d4-a716-446655440000}").


## Outputs

System.String Returns the GUID in hexadecimal format without dashes.


## Examples

### Example 1

```powershell
"550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-GuidToHex
```

Converts GUID to hex format: "550E8400E29B41D4A716446655440000"

## Aliases

This function has the following aliases:

- `guid-to-hex` - Converts a GUID to hexadecimal format (no dashes).


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/guid.ps1
