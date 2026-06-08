# ConvertFrom-HexToBase122

## Synopsis

Converts hexadecimal string to Base122 encoding.

## Description

Encodes a hexadecimal string to Base122 format.

## Signature

```powershell
ConvertFrom-HexToBase122
```

## Parameters

### -InputObject

The hexadecimal string to encode.


## Outputs

System.String Returns the Base122 encoded string.


## Examples

### Example 1

```powershell
"48656C6C6F" | ConvertFrom-HexToBase122
```

Converts hex to Base122 format.

## Aliases

This function has the following aliases:

- `hex-to-base122` - Converts hexadecimal string to Base122 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base122.ps1
