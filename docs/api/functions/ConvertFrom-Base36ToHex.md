# ConvertFrom-Base36ToHex

## Synopsis

Converts Base36 encoding to hexadecimal string.

## Description

Decodes Base36 encoded string to hexadecimal format.

## Signature

```powershell
ConvertFrom-Base36ToHex
```

## Parameters

### -InputObject

The Base36 encoded string to decode.


## Outputs

System.String Returns the hexadecimal string.


## Examples

### Example 1

`powershell
"91IXPRL3" | ConvertFrom-Base36ToHex
    
    Converts Base36 to hex format.
``

## Aliases

This function has the following aliases:

- `base36-to-hex` - Converts Base36 encoding to hexadecimal string.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base36.ps1
