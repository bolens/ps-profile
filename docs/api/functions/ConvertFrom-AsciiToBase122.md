# ConvertFrom-AsciiToBase122

## Synopsis

Converts ASCII text to Base122 encoding.

## Description

Encodes ASCII/UTF-8 text to Base122 format. Base122 is a URL-safe binary encoding using 122 printable ASCII characters.

## Signature

```powershell
ConvertFrom-AsciiToBase122
```

## Parameters

### -InputObject

The text string to encode.


## Outputs

System.String Returns the Base122 encoded string.


## Examples

### Example 1

`powershell
"Hello World" | ConvertFrom-AsciiToBase122
    
    Converts text to Base122 format.
``

## Aliases

This function has the following aliases:

- `ascii-to-base122` - Converts ASCII text to Base122 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base122.ps1
