# Initialize-FileConversion-CoreEncodingMorse

## Synopsis

Initializes Morse Code encoding conversion utility functions.

## Description

Sets up internal conversion functions for Morse Code encoding format. Morse Code uses dots (.) and dashes (-) to represent letters, numbers, and punctuation. Supports bidirectional conversions between Morse Code and ASCII text. This function is called automatically by Initialize-FileConversion-CoreEncoding.

## Signature

```powershell
Initialize-FileConversion-CoreEncodingMorse
```

## Parameters

No parameters.

## Examples

No examples provided.

## Notes

This is an internal initialization function and should not be called directly. Uses International Morse Code standard. Words are separated by spaces, letters within words are separated by single spaces.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/morse.ps1
