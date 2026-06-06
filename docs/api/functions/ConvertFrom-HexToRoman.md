# ConvertFrom-HexToRoman

## Synopsis

Converts hexadecimal string to Roman numeral representation.

## Description

Converts a hexadecimal string to Roman numeral string representation.

## Signature

```powershell
ConvertFrom-HexToRoman
```

## Parameters

### -InputObject

The hexadecimal string to convert. Can be piped.

### -Separator

Optional separator between Roman numerals. Default is a space.


## Outputs

System.String The Roman numeral representation of the input hex string.


## Examples

### Example 1

`powershell
"4865" | ConvertFrom-HexToRoman
    Converts hex to Roman numerals.
``

## Aliases

This function has the following aliases:

- `hex-to-roman` - Converts hexadecimal string to Roman numeral representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/hex.ps1
