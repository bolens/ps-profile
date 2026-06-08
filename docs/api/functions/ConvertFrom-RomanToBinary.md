# ConvertFrom-RomanToBinary

## Synopsis

Converts Roman numeral string to binary representation.

## Description

Converts a Roman numeral string to binary string representation.

## Signature

```powershell
ConvertFrom-RomanToBinary
```

## Parameters

### -InputObject

The Roman numeral string to convert. Can be piped.

### -Separator

Optional separator between binary bytes. Default is a space.


## Outputs

System.String The binary representation of the input Roman numeral string.


## Examples

### Example 1

```powershell
"LXXII CV" | ConvertFrom-RomanToBinary
```

Converts Roman numerals to binary.

## Aliases

This function has the following aliases:

- `roman-to-binary` - Converts Roman numeral string to binary representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/roman.ps1
