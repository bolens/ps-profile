# ConvertFrom-AsciiToMorse

## Synopsis

Converts ASCII text to Morse Code encoding.

## Description

Encodes ASCII text to International Morse Code format. Uses dots (.) and dashes (-) to represent characters. Words are separated by double spaces, letters within words by single spaces.

## Signature

```powershell
ConvertFrom-AsciiToMorse
```

## Parameters

### -InputObject

The text string to encode.


## Outputs

System.String Returns the Morse Code encoded string.


## Examples

### Example 1

```powershell
"HELLO WORLD" | ConvertFrom-AsciiToMorse
```

Converts text to Morse Code format.

### Example 2

```powershell
"SOS" | ConvertFrom-AsciiToMorse
```

Returns "... --- ..."

## Aliases

This function has the following aliases:

- `ascii-to-morse` - Converts ASCII text to Morse Code encoding.
- `morse` - Converts ASCII text to Morse Code encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/morse.ps1
