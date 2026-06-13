# ConvertFrom-RomanToOctal

## Synopsis

Converts Roman numeral string to octal representation.

## Description

Converts a Roman numeral string to octal string representation.

## Signature

```powershell
ConvertFrom-RomanToOctal
```

## Parameters

### -InputObject

The Roman numeral string to convert. Can be piped.

### -Separator

Optional separator between octal bytes. Default is a space.


## Outputs

System.String The octal representation of the input Roman numeral string.


## Examples

### Example 1

```powershell
"LXXII CV" | ConvertFrom-RomanToOctal
```

Converts Roman numerals to octal.

## Aliases

This function has the following aliases:

- `roman-to-octal` - Converts Roman numeral string to octal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/roman.ps1
