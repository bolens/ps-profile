# ConvertFrom-AsciiToBase85

## Synopsis

Converts ASCII text to Base85/Ascii85 encoding.

## Description

Encodes ASCII/UTF-8 text to Base85 format. Base85 is commonly used in PDF and PostScript files.

## Signature

```powershell
ConvertFrom-AsciiToBase85
```

## Parameters

### -InputObject

The text string to encode.


## Outputs

System.String Returns the Base85 encoded string.


## Examples

### Example 1

`powershell
"Hello World" | ConvertFrom-AsciiToBase85
    
    Converts text to Base85 format.
``

## Aliases

This function has the following aliases:

- `ascii-to-ascii85` - Converts ASCII text to Base85/Ascii85 encoding.
- `ascii-to-base85` - Converts ASCII text to Base85/Ascii85 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base85.ps1
