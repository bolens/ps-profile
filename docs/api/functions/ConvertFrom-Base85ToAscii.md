# ConvertFrom-Base85ToAscii

## Synopsis

Converts Base85/Ascii85 encoding to ASCII text.

## Description

Decodes Base85 encoded string back to ASCII/UTF-8 text.

## Signature

```powershell
ConvertFrom-Base85ToAscii
```

## Parameters

### -InputObject

The Base85 encoded string to decode.


## Outputs

System.String Returns the decoded ASCII text.


## Examples

### Example 1

`powershell
"87cURD]j7BEbo7" | ConvertFrom-Base85ToAscii
    
    Converts Base85 to text.
``

## Aliases

This function has the following aliases:

- `ascii85-to-ascii` - Converts Base85/Ascii85 encoding to ASCII text.
- `base85-to-ascii` - Converts Base85/Ascii85 encoding to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base85.ps1
