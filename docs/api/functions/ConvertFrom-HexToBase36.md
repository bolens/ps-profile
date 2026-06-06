# ConvertFrom-HexToBase36

## Synopsis

Converts hexadecimal string to Base36 encoding.

## Description

Encodes a hexadecimal string to Base36 format.

## Signature

```powershell
ConvertFrom-HexToBase36
```

## Parameters

### -InputObject

The hexadecimal string to encode.


## Outputs

System.String Returns the Base36 encoded string.


## Examples

### Example 1

`powershell
"48656C6C6F" | ConvertFrom-HexToBase36
    
    Converts hex to Base36 format.
``

## Aliases

This function has the following aliases:

- `hex-to-base36` - Converts hexadecimal string to Base36 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base36.ps1
