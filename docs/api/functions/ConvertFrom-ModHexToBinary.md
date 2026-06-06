# ConvertFrom-ModHexToBinary

## Synopsis

Converts ModHex string to binary representation.

## Description

Converts a ModHex (modified hexadecimal) string to binary string representation. First converts ModHex to hex, then hex to binary.

## Signature

```powershell
ConvertFrom-ModHexToBinary
```

## Parameters

### -InputObject

The ModHex string to convert. Can be piped. Spaces are automatically removed.

### -Separator

Optional separator between binary bytes. Default is a space.


## Outputs

System.String The binary representation of the input ModHex string.


## Examples

### Example 1

`powershell
"hkkllkkl" | ConvertFrom-ModHexToBinary
    Converts ModHex to binary with spaces.
``

### Example 2

`powershell
ConvertFrom-ModHexToBinary -InputObject "hkkllkkl" -Separator ""
    Converts ModHex to binary without separator.
``

## Aliases

This function has the following aliases:

- `modhex-to-binary` - Converts ModHex string to binary representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/modhex.ps1
