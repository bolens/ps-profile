# ConvertFrom-AsciiToRot13

## Synopsis

Converts ASCII text to ROT13 cipher encoding.

## Description

Encodes ASCII text using ROT13 cipher (rotates letters by 13 positions). ROT13 is a self-inverse cipher - applying it twice returns the original text.

## Signature

```powershell
ConvertFrom-AsciiToRot13
```

## Parameters

### -InputObject

The text string to encode.


## Outputs

System.String Returns the ROT13 encoded string.


## Examples

### Example 1

```powershell
"Hello World" | ConvertFrom-AsciiToRot13
```

Converts text to ROT13 format.

### Example 2

```powershell
"Uryyb Jbeyq" | ConvertFrom-Rot13ToAscii
```

Decodes ROT13 back to original text.

## Aliases

This function has the following aliases:

- `ascii-to-rot13` - Converts ASCII text to ROT13 cipher encoding.
- `rot13` - Converts ASCII text to ROT13 cipher encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/rot.ps1
