# ConvertFrom-DecimalToRoman

## Synopsis

Converts decimal string to Roman numeral representation.

## Description

Converts a decimal string to Roman numeral string representation.

## Signature

```powershell
ConvertFrom-DecimalToRoman
```

## Parameters

### -InputObject

The decimal string to convert. Can be piped.

### -Separator

Optional separator between Roman numerals. Default is a space.


## Outputs

System.String The Roman numeral representation of the input decimal string.


## Examples

### Example 1

`powershell
"72 105" | ConvertFrom-DecimalToRoman
    Converts decimal to Roman numerals.
``

## Aliases

This function has the following aliases:

- `decimal-to-roman` - Converts decimal string to Roman numeral representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
