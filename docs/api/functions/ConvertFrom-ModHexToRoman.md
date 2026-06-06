# ConvertFrom-ModHexToRoman

## Synopsis

Converts ModHex string to Roman numeral representation.

## Description

Converts a ModHex string to Roman numeral string representation.

## Signature

```powershell
ConvertFrom-ModHexToRoman
```

## Parameters

### -InputObject

The ModHex string to convert. Can be piped.

### -Separator

Optional separator between Roman numerals. Default is a space.


## Outputs

System.String The Roman numeral representation of the input ModHex string.


## Examples

### Example 1

`powershell
"hkkllkkl" | ConvertFrom-ModHexToRoman
    Converts ModHex to Roman numerals.
``

## Aliases

This function has the following aliases:

- `modhex-to-roman` - Converts ModHex string to Roman numeral representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/modhex.ps1
