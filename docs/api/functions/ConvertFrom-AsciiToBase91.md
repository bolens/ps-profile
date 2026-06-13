# ConvertFrom-AsciiToBase91

## Synopsis

Converts ASCII text to Base91 encoding.

## Description

Encodes ASCII/UTF-8 text to Base91 format. Base91 is more efficient than Base64, providing better compression ratio.

## Signature

```powershell
ConvertFrom-AsciiToBase91
```

## Parameters

### -InputObject

The text string to encode.


## Outputs

System.String Returns the Base91 encoded string.


## Examples

### Example 1

```powershell
"Hello World" | ConvertFrom-AsciiToBase91
```

Converts text to Base91 format.

## Aliases

This function has the following aliases:

- `ascii-to-base91` - Converts ASCII text to Base91 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base91.ps1
