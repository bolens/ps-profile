# ConvertFrom-Base64ToBase85

## Synopsis

Converts Base64 encoding to Base85 encoding.

## Description

Converts a Base64 encoded string to Base85 format.

## Signature

```powershell
ConvertFrom-Base64ToBase85
```

## Parameters

### -InputObject

The Base64 encoded string to convert.


## Outputs

System.String Returns the Base85 encoded string.


## Examples

### Example 1

`powershell
"SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase85
    
    Converts Base64 to Base85 format.
``

## Aliases

This function has the following aliases:

- `base64-to-base85` - Converts Base64 encoding to Base85 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base85.ps1
