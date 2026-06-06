# ConvertFrom-Base32ToRoman

## Synopsis

Converts Base32 string to Roman numeral representation.

## Description

Converts a Base32 string to Roman numeral string representation.

## Signature

```powershell
ConvertFrom-Base32ToRoman
```

## Parameters

### -InputObject

The Base32 string to convert. Can be piped.

### -Separator

Optional separator between Roman numerals. Default is a space.


## Outputs

System.String The Roman numeral representation of the input Base32 string.


## Examples

### Example 1

`powershell
"JBSWY3DP" | ConvertFrom-Base32ToRoman
    Converts Base32 to Roman numerals.
``

## Aliases

This function has the following aliases:

- `base32-to-roman` - Converts Base32 string to Roman numeral representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base32.ps1
