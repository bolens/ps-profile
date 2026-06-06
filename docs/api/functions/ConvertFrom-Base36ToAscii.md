# ConvertFrom-Base36ToAscii

## Synopsis

Converts Base36 encoding to ASCII text.

## Description

Decodes Base36 encoded string back to ASCII/UTF-8 text.

## Signature

```powershell
ConvertFrom-Base36ToAscii
```

## Parameters

### -InputObject

The Base36 encoded string to decode.


## Outputs

System.String Returns the decoded ASCII text.


## Examples

### Example 1

`powershell
"91IXPRL3" | ConvertFrom-Base36ToAscii
    
    Converts Base36 to text.
``

## Aliases

This function has the following aliases:

- `base36-to-ascii` - Converts Base36 encoding to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base36.ps1
