# ConvertFrom-HexToBase58

## Synopsis

Converts hexadecimal string to Base58 encoding.

## Description

Encodes a hexadecimal string to Base58 format.

## Signature

```powershell
ConvertFrom-HexToBase58
```

## Parameters

### -InputObject

The hexadecimal string to encode.


## Outputs

System.String Returns the Base58 encoded string.


## Examples

### Example 1

```powershell
"48656C6C6F" | ConvertFrom-HexToBase58
```

Converts hex to Base58 format.

## Aliases

This function has the following aliases:

- `hex-to-base58` - Converts hexadecimal string to Base58 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base58.ps1
