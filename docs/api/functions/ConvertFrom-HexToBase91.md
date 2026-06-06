# ConvertFrom-HexToBase91

## Synopsis

Converts hexadecimal string to Base91 encoding.

## Description

Encodes a hexadecimal string to Base91 format.

## Signature

```powershell
ConvertFrom-HexToBase91
```

## Parameters

### -InputObject

The hexadecimal string to encode.


## Outputs

System.String Returns the Base91 encoded string.


## Examples

### Example 1

`powershell
"48656C6C6F" | ConvertFrom-HexToBase91
    
    Converts hex to Base91 format.
``

## Aliases

This function has the following aliases:

- `hex-to-base91` - Converts hexadecimal string to Base91 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base91.ps1
