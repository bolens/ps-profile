# ConvertFrom-AsciiToBinary

## Synopsis

Converts ASCII text to binary representation.

## Description

Converts ASCII text to binary string representation. Each character is converted to its UTF-8 byte representation in binary.

## Signature

```powershell
ConvertFrom-AsciiToBinary
```

## Parameters

### -InputObject

The ASCII text to convert. Can be piped.

### -Separator

Optional separator between binary bytes. Default is a space.


## Outputs

System.String The binary representation of the input text.


## Examples

### Example 1

`powershell
"Hi" | ConvertFrom-AsciiToBinary
    Converts "Hi" to "01001000 01101001".
``

### Example 2

`powershell
ConvertFrom-AsciiToBinary -InputObject "AB" -Separator ""
    Converts "AB" to "0100000101000010" (no separator).
``

## Aliases

This function has the following aliases:

- `ascii-to-binary` - Converts ASCII text to binary representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/ascii.ps1
