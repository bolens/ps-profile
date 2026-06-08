# ConvertFrom-Base58ToHex

## Synopsis

Converts Base58 encoding to hexadecimal string.

## Description

Decodes Base58 encoded string to hexadecimal format.

## Signature

```powershell
ConvertFrom-Base58ToHex
```

## Parameters

### -InputObject

The Base58 encoded string to decode.


## Outputs

System.String Returns the hexadecimal string.


## Examples

### Example 1

```powershell
"JxF12TrwUP45BMd" | ConvertFrom-Base58ToHex
```

Converts Base58 to hex format.

## Aliases

This function has the following aliases:

- `base58-to-hex` - Converts Base58 encoding to hexadecimal string.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base58.ps1
