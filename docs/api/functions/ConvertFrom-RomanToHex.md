# ConvertFrom-RomanToHex

## Synopsis

Converts Roman numeral string to hexadecimal representation.

## Description

Converts a Roman numeral string to hexadecimal string representation.

## Signature

```powershell
ConvertFrom-RomanToHex
```

## Parameters

### -InputObject

The Roman numeral string to convert. Can be piped.


## Outputs

System.String The hexadecimal representation of the input Roman numeral string.


## Examples

### Example 1

`powershell
"LXXII CV" | ConvertFrom-RomanToHex
    Converts Roman numerals to hex.
``

## Aliases

This function has the following aliases:

- `roman-to-hex` - Converts Roman numeral string to hexadecimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/roman.ps1
