# ConvertFrom-RomanToModHex

## Synopsis

Converts Roman numeral string to ModHex representation.

## Description

Converts a Roman numeral string to ModHex string representation.

## Signature

```powershell
ConvertFrom-RomanToModHex
```

## Parameters

### -InputObject

The Roman numeral string to convert. Can be piped.


## Outputs

System.String The ModHex representation of the input Roman numeral string.


## Examples

### Example 1

`powershell
"LXXII CV" | ConvertFrom-RomanToModHex
    Converts Roman numerals to ModHex.
``

## Aliases

This function has the following aliases:

- `roman-to-modhex` - Converts Roman numeral string to ModHex representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/roman.ps1
