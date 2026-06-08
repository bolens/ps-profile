# ConvertFrom-AsciiToBraille

## Synopsis

Converts ASCII text to Braille encoding.

## Description

Encodes ASCII text to Unicode Braille patterns. Uses standard 6-dot Braille patterns (U+2800-U+28FF).

## Signature

```powershell
ConvertFrom-AsciiToBraille
```

## Parameters

### -InputObject

The text string to encode.


## Outputs

System.String Returns the Braille encoded string (Unicode characters).


## Examples

### Example 1

```powershell
"HELLO" | ConvertFrom-AsciiToBraille
```

Converts text to Braille Unicode format.

### Example 2

```powershell
"123" | ConvertFrom-AsciiToBraille
```

Converts numbers to Braille (with number sign prefix).

## Aliases

This function has the following aliases:

- `ascii-to-braille` - Converts ASCII text to Braille encoding.
- `braille` - Converts ASCII text to Braille encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/braille.ps1
