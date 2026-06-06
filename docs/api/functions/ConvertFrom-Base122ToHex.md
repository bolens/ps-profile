# ConvertFrom-Base122ToHex

## Synopsis

Converts Base122 encoding to hexadecimal string.

## Description

Decodes Base122 encoded string to hexadecimal format.

## Signature

```powershell
ConvertFrom-Base122ToHex
```

## Parameters

### -InputObject

The Base122 encoded string to decode.


## Outputs

System.String Returns the hexadecimal string.


## Examples

### Example 1

`powershell
"48656C6C6F" | ConvertFrom-HexToBase122 | ConvertFrom-Base122ToHex
    
    Converts Base122 to hex format.
``

## Aliases

This function has the following aliases:

- `base122-to-hex` - Converts Base122 encoding to hexadecimal string.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base122.ps1
