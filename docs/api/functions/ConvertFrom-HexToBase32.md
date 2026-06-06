# ConvertFrom-HexToBase32

## Synopsis

Converts hexadecimal string to Base32 representation.

## Description

Converts a hexadecimal string to Base32 string representation.

## Signature

```powershell
ConvertFrom-HexToBase32
```

## Parameters

### -InputObject

The hexadecimal string to convert. Can be piped. Spaces and separators are automatically removed.


## Outputs

System.String The Base32 representation of the input hex string.


## Examples

### Example 1

`powershell
"48656C6C6F" | ConvertFrom-HexToBase32
    Converts hex to Base32.
``

## Aliases

This function has the following aliases:

- `hex-to-base32` - Converts hexadecimal string to Base32 representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/hex.ps1
