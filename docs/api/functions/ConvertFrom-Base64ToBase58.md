# ConvertFrom-Base64ToBase58

## Synopsis

Converts Base64 encoding to Base58 encoding.

## Description

Converts a Base64 encoded string to Base58 format.

## Signature

```powershell
ConvertFrom-Base64ToBase58
```

## Parameters

### -InputObject

The Base64 encoded string to convert.


## Outputs

System.String Returns the Base58 encoded string.


## Examples

### Example 1

`powershell
"SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase58
    
    Converts Base64 to Base58 format.
``

## Aliases

This function has the following aliases:

- `base64-to-base58` - Converts Base64 encoding to Base58 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base58.ps1
