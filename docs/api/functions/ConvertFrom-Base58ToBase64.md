# ConvertFrom-Base58ToBase64

## Synopsis

Converts Base58 encoding to Base64 encoding.

## Description

Converts a Base58 encoded string to Base64 format.

## Signature

```powershell
ConvertFrom-Base58ToBase64
```

## Parameters

### -InputObject

The Base58 encoded string to convert.


## Outputs

System.String Returns the Base64 encoded string.


## Examples

### Example 1

`powershell
"JxF12TrwUP45BMd" | ConvertFrom-Base58ToBase64
    
    Converts Base58 to Base64 format.
``

## Aliases

This function has the following aliases:

- `base58-to-base64` - Converts Base58 encoding to Base64 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base58.ps1
