# ConvertFrom-AsciiToRoman

## Synopsis

Converts ASCII text to Roman numeral representation.

## Description

Converts ASCII text to Roman numeral string representation. Each character is converted to its UTF-8 byte value as a Roman numeral.

## Signature

```powershell
ConvertFrom-AsciiToRoman
```

## Parameters

### -InputObject

The ASCII text to convert. Can be piped.

### -Separator

Optional separator between Roman numerals. Default is a space.


## Outputs

System.String The Roman numeral representation of the input text.


## Examples

### Example 1

`powershell
"A" | ConvertFrom-AsciiToRoman
    Converts "A" to "LXXII" (65 in Roman).
``

### Example 2

`powershell
ConvertFrom-AsciiToRoman -InputObject "Hi" -Separator ","
    Converts "Hi" to "LXXII,CV" (comma separator).
``

## Aliases

This function has the following aliases:

- `ascii-to-roman` - Converts ASCII text to Roman numeral representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/ascii.ps1
