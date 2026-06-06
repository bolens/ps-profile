# ConvertFrom-RomanToAscii

## Synopsis

Converts Roman numeral string to ASCII text.

## Description

Converts a Roman numeral string back to ASCII text. The Roman numerals should represent UTF-8 byte values (1-255).

## Signature

```powershell
ConvertFrom-RomanToAscii
```

## Parameters

### -InputObject

The Roman numeral string to convert. Can be piped. Roman numerals should be separated by spaces.


## Outputs

System.String The ASCII text representation of the input Roman numeral string.


## Examples

### Example 1

`powershell
"LXXII CV" | ConvertFrom-RomanToAscii
    Converts Roman numerals to "Hi".
``

### Example 2

`powershell
ConvertFrom-RomanToAscii -InputObject "LXV LXVII"
    Converts Roman numerals to "AB".
``

## Aliases

This function has the following aliases:

- `roman-to-ascii` - Converts Roman numeral string to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/roman.ps1
