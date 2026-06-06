# ConvertFrom-BinaryToDecimal

## Synopsis

Converts binary string to decimal representation.

## Description

Converts a binary string to decimal string representation.

## Signature

```powershell
ConvertFrom-BinaryToDecimal
```

## Parameters

### -InputObject

The binary string to convert. Can be piped.

### -Separator

Optional separator between decimal values. Default is a space.


## Outputs

System.String The decimal representation of the input binary string.


## Examples

### Example 1

`powershell
"01001000 01101001" | ConvertFrom-BinaryToDecimal
    Converts binary to decimal.
``

## Aliases

This function has the following aliases:

- `binary-to-decimal` - Converts binary string to decimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/binary.ps1
