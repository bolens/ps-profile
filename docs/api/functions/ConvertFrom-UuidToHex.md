# ConvertFrom-UuidToHex

## Synopsis

Converts a UUID to hexadecimal format (no dashes).

## Description

Converts a UUID string to hexadecimal format without dashes.

## Signature

```powershell
ConvertFrom-UuidToHex [String]$Uuid
```

## Parameters

### -Uuid

**Type:** [String]

The UUID string to convert (e.g., "550e8400-e29b-41d4-a716-446655440000").


## Outputs

System.String Returns the UUID in hexadecimal format without dashes.


## Examples

### Example 1

`powershell
"550e8400-e29b-41d4-a716-446655440000" | ConvertFrom-UuidToHex
    
    Converts UUID to hex format: "550E8400E29B41D4A716446655440000"
``

## Aliases

This function has the following aliases:

- `uuid-to-hex` - Converts a UUID to hexadecimal format (no dashes).


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/uuid.ps1
