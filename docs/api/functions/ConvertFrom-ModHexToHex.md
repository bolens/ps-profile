# ConvertFrom-ModHexToHex

## Synopsis

Converts ModHex string to hexadecimal representation.

## Description

Converts a ModHex (modified hexadecimal) string to standard hexadecimal representation.

## Signature

```powershell
ConvertFrom-ModHexToHex
```

## Parameters

### -InputObject

The ModHex string to convert. Can be piped. Spaces are automatically removed.


## Outputs

System.String The hexadecimal representation of the input ModHex string.


## Examples

### Example 1

`powershell
"hkkllkkl" | ConvertFrom-ModHexToHex
    Converts ModHex to hex.
``

### Example 2

`powershell
ConvertFrom-ModHexToHex -InputObject "hkkllkkl"
    Converts ModHex string to hex.
``

## Aliases

This function has the following aliases:

- `modhex-to-hex` - Converts ModHex string to hexadecimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/modhex.ps1
