# ConvertFrom-BinaryToBase32

## Synopsis

Converts binary string to Base32 representation.

## Description

Converts a binary string to Base32 string representation.

## Signature

```powershell
ConvertFrom-BinaryToBase32
```

## Parameters

### -InputObject

The binary string to convert. Can be piped. Spaces are automatically removed.


## Outputs

System.String The Base32 representation of the input binary string.


## Examples

### Example 1

`powershell
"01001000 01101001" | ConvertFrom-BinaryToBase32
    Converts binary to Base32.
``

## Aliases

This function has the following aliases:

- `binary-to-base32` - Converts binary string to Base32 representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/binary.ps1
