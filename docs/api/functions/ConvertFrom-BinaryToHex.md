# ConvertFrom-BinaryToHex

## Synopsis

Converts binary string to hexadecimal representation.

## Description

Converts a binary string to hexadecimal string representation. Each 8-bit binary chunk is converted to a hex byte.

## Signature

```powershell
ConvertFrom-BinaryToHex
```

## Parameters

### -InputObject

The binary string to convert. Can be piped. Spaces are automatically removed.


## Outputs

System.String The hexadecimal representation of the input binary string.


## Examples

### Example 1

```powershell
"01001000 01101001" | ConvertFrom-BinaryToHex
```

Converts binary to hex.

### Example 2

```powershell
ConvertFrom-BinaryToHex -InputObject "11111111"
```

Converts binary to "FF".

## Aliases

This function has the following aliases:

- `binary-to-hex` - Converts binary string to hexadecimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/binary.ps1
