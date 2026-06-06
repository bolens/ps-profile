# ConvertFrom-AsciiToRot47

## Synopsis

Converts ASCII text to ROT47 cipher encoding.

## Description

Encodes ASCII text using ROT47 cipher (rotates all printable ASCII characters by 47 positions). ROT47 is a self-inverse cipher - applying it twice returns the original text. Unlike ROT13, ROT47 also encodes numbers and special characters.

## Signature

```powershell
ConvertFrom-AsciiToRot47
```

## Parameters

### -InputObject

The text string to encode.


## Outputs

System.String Returns the ROT47 encoded string.


## Examples

### Example 1

`powershell
"Hello World!" | ConvertFrom-AsciiToRot47
    
    Converts text to ROT47 format.
``

### Example 2

`powershell
"w6==@ (@C=5P" | ConvertFrom-Rot47ToAscii
    
    Decodes ROT47 back to original text.
``

## Aliases

This function has the following aliases:

- `ascii-to-rot47` - Converts ASCII text to ROT47 cipher encoding.
- `rot47` - Converts ASCII text to ROT47 cipher encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/rot.ps1
