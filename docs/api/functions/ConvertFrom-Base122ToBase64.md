# ConvertFrom-Base122ToBase64

## Synopsis

Converts Base122 encoding to Base64 encoding.

## Description

Converts a Base122 encoded string to Base64 format.

## Signature

```powershell
ConvertFrom-Base122ToBase64
```

## Parameters

### -InputObject

The Base122 encoded string to convert.


## Outputs

System.String Returns the Base64 encoded string.


## Examples

### Example 1

`powershell
"SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase122 | ConvertFrom-Base122ToBase64
    
    Converts Base122 to Base64 format.
``

## Aliases

This function has the following aliases:

- `base122-to-base64` - Converts Base122 encoding to Base64 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base122.ps1
