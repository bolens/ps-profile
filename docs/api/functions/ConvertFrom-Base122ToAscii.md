# ConvertFrom-Base122ToAscii

## Synopsis

Converts Base122 encoding to ASCII text.

## Description

Decodes Base122 encoded string back to ASCII/UTF-8 text.

## Signature

```powershell
ConvertFrom-Base122ToAscii
```

## Parameters

### -InputObject

The Base122 encoded string to decode.


## Outputs

System.String Returns the decoded ASCII text.


## Examples

### Example 1

`powershell
"Hello World" | ConvertFrom-AsciiToBase122 | ConvertFrom-Base122ToAscii
    
    Converts Base122 to text.
``

## Aliases

This function has the following aliases:

- `base122-to-ascii` - Converts Base122 encoding to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base122.ps1
