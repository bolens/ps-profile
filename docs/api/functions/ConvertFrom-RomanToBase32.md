# ConvertFrom-RomanToBase32

## Synopsis

Converts Roman numeral string to Base32 representation.

## Description

Converts a Roman numeral string to Base32 string representation.

## Signature

```powershell
ConvertFrom-RomanToBase32
```

## Parameters

### -InputObject

The Roman numeral string to convert. Can be piped.


## Outputs

System.String The Base32 representation of the input Roman numeral string.


## Examples

### Example 1

```powershell
"LXXII CV" | ConvertFrom-RomanToBase32
```

Converts Roman numerals to Base32.

## Aliases

This function has the following aliases:

- `roman-to-base32` - Converts Roman numeral string to Base32 representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/roman.ps1
