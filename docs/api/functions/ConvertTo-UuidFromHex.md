# ConvertTo-UuidFromHex

## Synopsis

Converts a hexadecimal string to UUID format.

## Description

Converts a 32-character hexadecimal string to standard UUID format with dashes.

## Signature

```powershell
ConvertTo-UuidFromHex [String]$Hex
```

## Parameters

### -Hex

**Type:** [String]

**Attributes:** Mandatory

The hexadecimal string to convert (32 characters, with or without dashes).


## Outputs

System.String Returns the UUID in standard format with dashes.


## Examples

### Example 1

`powershell
"550E8400E29B41D4A716446655440000" | ConvertTo-UuidFromHex
    
    Converts hex to UUID format: "550e8400-e29b-41d4-a716-446655440000"
``

## Aliases

This function has the following aliases:

- `hex-to-uuid` - Converts a hexadecimal string to UUID format.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/uuid.ps1
