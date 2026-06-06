# ConvertFrom-AsciiToHex

## Synopsis

Converts ASCII text to hexadecimal representation.

## Description

Converts ASCII text to hexadecimal string representation. Each character is converted to its UTF-8 byte representation in hex.

## Signature

```powershell
ConvertFrom-AsciiToHex
```

## Parameters

### -InputObject

The ASCII text to convert. Can be piped.


## Outputs

System.String The hexadecimal representation of the input text.


## Examples

### Example 1

`powershell
"Hello" | ConvertFrom-AsciiToHex
    Converts "Hello" to "48656C6C6F".
``

### Example 2

`powershell
ConvertFrom-AsciiToHex -InputObject "World"
    Converts "World" to "576F726C64".
``

## Aliases

This function has the following aliases:

- `ascii-to-hex` - Converts ASCII text to hexadecimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/ascii.ps1
