# ConvertFrom-Base64ToBase36

## Synopsis

Converts Base64 encoding to Base36 encoding.

## Description

Converts a Base64 encoded string to Base36 format.

## Signature

```powershell
ConvertFrom-Base64ToBase36
```

## Parameters

### -InputObject

The Base64 encoded string to convert.


## Outputs

System.String Returns the Base36 encoded string.


## Examples

### Example 1

`powershell
"SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase36
    
    Converts Base64 to Base36 format.
``

## Aliases

This function has the following aliases:

- `base64-to-base36` - Converts Base64 encoding to Base36 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base36.ps1
