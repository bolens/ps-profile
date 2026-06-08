# ConvertFrom-HexToBase85

## Synopsis

Converts hexadecimal string to Base85 encoding.

## Description

Encodes a hexadecimal string to Base85 format.

## Signature

```powershell
ConvertFrom-HexToBase85
```

## Parameters

### -InputObject

The hexadecimal string to encode.


## Outputs

System.String Returns the Base85 encoded string.


## Examples

### Example 1

```powershell
"48656C6C6F" | ConvertFrom-HexToBase85
```

Converts hex to Base85 format.

## Aliases

This function has the following aliases:

- `hex-to-base85` - Converts hexadecimal string to Base85 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base85.ps1
