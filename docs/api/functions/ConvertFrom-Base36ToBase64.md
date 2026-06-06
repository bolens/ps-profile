# ConvertFrom-Base36ToBase64

## Synopsis

Converts Base36 encoding to Base64 encoding.

## Description

Converts a Base36 encoded string to Base64 format.

## Signature

```powershell
ConvertFrom-Base36ToBase64
```

## Parameters

### -InputObject

The Base36 encoded string to convert.


## Outputs

System.String Returns the Base64 encoded string.


## Examples

### Example 1

`powershell
"91IXPRL3" | ConvertFrom-Base36ToBase64
    
    Converts Base36 to Base64 format.
``

## Aliases

This function has the following aliases:

- `base36-to-base64` - Converts Base36 encoding to Base64 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base36.ps1
