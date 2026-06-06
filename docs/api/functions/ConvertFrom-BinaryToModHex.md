# ConvertFrom-BinaryToModHex

## Synopsis

Converts binary string to ModHex representation.

## Description

Converts a binary string to ModHex (modified hexadecimal) representation. First converts binary to hex, then hex to ModHex.

## Signature

```powershell
ConvertFrom-BinaryToModHex
```

## Parameters

### -InputObject

The binary string to convert. Can be piped. Spaces are automatically removed.


## Outputs

System.String The ModHex representation of the input binary string.


## Examples

### Example 1

`powershell
"01001000 01101001" | ConvertFrom-BinaryToModHex
    Converts binary to ModHex.
``

### Example 2

`powershell
ConvertFrom-BinaryToModHex -InputObject "11111111"
    Converts binary to ModHex.
``

## Aliases

This function has the following aliases:

- `binary-to-modhex` - Converts binary string to ModHex representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/binary.ps1
