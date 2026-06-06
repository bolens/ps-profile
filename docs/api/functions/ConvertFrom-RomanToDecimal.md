# ConvertFrom-RomanToDecimal

## Synopsis

Converts Roman numeral string to decimal representation.

## Description

Converts a Roman numeral string to decimal string representation.

## Signature

```powershell
ConvertFrom-RomanToDecimal
```

## Parameters

### -InputObject

The Roman numeral string to convert. Can be piped.

### -Separator

Optional separator between decimal values. Default is a space.


## Outputs

System.String The decimal representation of the input Roman numeral string.


## Examples

### Example 1

`powershell
"LXXII CV" | ConvertFrom-RomanToDecimal
    Converts Roman numerals to decimal.
``

## Aliases

This function has the following aliases:

- `roman-to-decimal` - Converts Roman numeral string to decimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/roman.ps1
