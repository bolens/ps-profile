# ConvertFrom-BinaryToRoman

## Synopsis

Converts binary string to Roman numeral representation.

## Description

Converts a binary string to Roman numeral string representation.

## Signature

```powershell
ConvertFrom-BinaryToRoman
```

## Parameters

### -InputObject

The binary string to convert. Can be piped.

### -Separator

Optional separator between Roman numerals. Default is a space.


## Outputs

System.String The Roman numeral representation of the input binary string.


## Examples

### Example 1

`powershell
"01001000 01101001" | ConvertFrom-BinaryToRoman
    Converts binary to Roman numerals.
``

## Aliases

This function has the following aliases:

- `binary-to-roman` - Converts binary string to Roman numeral representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/binary.ps1
