# ConvertFrom-OctalToRoman

## Synopsis

Converts octal string to Roman numeral representation.

## Description

Converts an octal string to Roman numeral string representation.

## Signature

```powershell
ConvertFrom-OctalToRoman
```

## Parameters

### -InputObject

The octal string to convert. Can be piped.

### -Separator

Optional separator between Roman numerals. Default is a space.


## Outputs

System.String The Roman numeral representation of the input octal string.


## Examples

### Example 1

```powershell
"110 151" | ConvertFrom-OctalToRoman
```

Converts octal to Roman numerals.

## Aliases

This function has the following aliases:

- `octal-to-roman` - Converts octal string to Roman numeral representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
