# ConvertFrom-OctalToBinary

## Synopsis

Converts octal string to binary representation.

## Description

Converts an octal string to binary string representation.

## Signature

```powershell
ConvertFrom-OctalToBinary
```

## Parameters

### -InputObject

The octal string to convert. Can be piped.

### -Separator

Optional separator between binary bytes. Default is a space.


## Outputs

System.String The binary representation of the input octal string.


## Examples

### Example 1

`powershell
"110 151" | ConvertFrom-OctalToBinary
    Converts octal to binary.
``

## Aliases

This function has the following aliases:

- `octal-to-binary` - Converts octal string to binary representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
