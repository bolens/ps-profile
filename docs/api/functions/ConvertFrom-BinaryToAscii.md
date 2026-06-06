# ConvertFrom-BinaryToAscii

## Synopsis

Converts binary string to ASCII text.

## Description

Converts a binary string back to ASCII text. The binary string should contain 8-bit chunks representing UTF-8 bytes.

## Signature

```powershell
ConvertFrom-BinaryToAscii
```

## Parameters

### -InputObject

The binary string to convert. Can be piped. Spaces are automatically removed.


## Outputs

System.String The ASCII text representation of the input binary string.


## Examples

### Example 1

`powershell
"01001000 01101001" | ConvertFrom-BinaryToAscii
    Converts binary to "Hi".
``

### Example 2

`powershell
ConvertFrom-BinaryToAscii -InputObject "0100000101000010"
    Converts binary without spaces to "AB".
``

## Aliases

This function has the following aliases:

- `binary-to-ascii` - Converts binary string to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/binary.ps1
