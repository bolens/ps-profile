# ConvertFrom-BinaryToOctal

## Synopsis

Converts binary string to octal representation.

## Description

Converts a binary string to octal string representation.

## Signature

```powershell
ConvertFrom-BinaryToOctal
```

## Parameters

### -InputObject

The binary string to convert. Can be piped.

### -Separator

Optional separator between octal bytes. Default is a space.


## Outputs

System.String The octal representation of the input binary string.


## Examples

### Example 1

`powershell
"01001000 01101001" | ConvertFrom-BinaryToOctal
    Converts binary to octal.
``

## Aliases

This function has the following aliases:

- `binary-to-octal` - Converts binary string to octal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/binary.ps1
