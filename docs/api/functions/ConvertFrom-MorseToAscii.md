# ConvertFrom-MorseToAscii

## Synopsis

Converts Morse Code encoding to ASCII text.

## Description

Decodes Morse Code encoded string back to ASCII text. Supports International Morse Code standard.

## Signature

```powershell
ConvertFrom-MorseToAscii
```

## Parameters

### -InputObject

The Morse Code encoded string to decode.


## Outputs

System.String Returns the decoded ASCII text.


## Examples

### Example 1

```powershell
".... . .-.. .-.. ---  .-- --- .-. .-.. -.." | ConvertFrom-MorseToAscii
```

Converts Morse Code to text.

### Example 2

```powershell
"... --- ..." | ConvertFrom-MorseToAscii
```

Returns "SOS"

## Aliases

This function has the following aliases:

- `morse-to-ascii` - Converts Morse Code encoding to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/morse.ps1
