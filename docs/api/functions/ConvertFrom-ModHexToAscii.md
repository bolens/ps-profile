# ConvertFrom-ModHexToAscii

## Synopsis

Converts ModHex string to ASCII text.

## Description

Converts a ModHex (modified hexadecimal) string back to ASCII text. ModHex uses characters: c, b, d, e, f, g, h, i, j, k, l, n, r, t, u, v.

## Signature

```powershell
ConvertFrom-ModHexToAscii
```

## Parameters

### -InputObject

The ModHex string to convert. Can be piped. Spaces are automatically removed.


## Outputs

System.String The ASCII text representation of the input ModHex string.


## Examples

### Example 1

```powershell
"hkkllkkl" | ConvertFrom-ModHexToAscii
```

Converts ModHex to ASCII text.

### Example 2

```powershell
ConvertFrom-ModHexToAscii -InputObject "hkkllkkl"
```

Converts ModHex string to ASCII.

## Aliases

This function has the following aliases:

- `modhex-to-ascii` - Converts ModHex string to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/modhex.ps1
