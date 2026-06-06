# ConvertFrom-HexToModHex

## Synopsis

Converts hexadecimal string to ModHex representation.

## Description

Converts a hexadecimal string to ModHex (modified hexadecimal) representation. ModHex uses characters: c, b, d, e, f, g, h, i, j, k, l, n, r, t, u, v.

## Signature

```powershell
ConvertFrom-HexToModHex
```

## Parameters

### -InputObject

The hexadecimal string to convert. Can be piped. Spaces and separators are automatically removed.


## Outputs

System.String The ModHex representation of the input hex string.


## Examples

### Example 1

`powershell
"4865" | ConvertFrom-HexToModHex
    Converts hex to ModHex.
``

### Example 2

`powershell
ConvertFrom-HexToModHex -InputObject "FF"
    Converts hex to ModHex.
``

## Aliases

This function has the following aliases:

- `hex-to-modhex` - Converts hexadecimal string to ModHex representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/hex.ps1
