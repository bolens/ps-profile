# ConvertTo-GuidFromHex

## Synopsis

Converts a hexadecimal string to GUID format.

## Description

Converts a 32-character hexadecimal string to standard GUID format with dashes.

## Signature

```powershell
ConvertTo-GuidFromHex [String]$Hex, [SwitchParameter]$RegistryFormat
```

## Parameters

### -Hex

**Type:** [String]

The hexadecimal string to convert (32 characters).

### -RegistryFormat

**Type:** [SwitchParameter]

Return the GUID in Windows registry format with braces.


## Outputs

System.String Returns the GUID in standard format with dashes (or registry format if specified).


## Examples

### Example 1

`powershell
"550E8400E29B41D4A716446655440000" | ConvertTo-GuidFromHex
    
    Converts hex to GUID format: "550e8400-e29b-41d4-a716-446655440000"
``

### Example 2

`powershell
"550E8400E29B41D4A716446655440000" | ConvertTo-GuidFromHex -RegistryFormat
    
    Converts hex to GUID registry format: "{550e8400-e29b-41d4-a716-446655440000}"
``

## Aliases

This function has the following aliases:

- `hex-to-guid` - Converts a hexadecimal string to GUID format.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/guid.ps1
