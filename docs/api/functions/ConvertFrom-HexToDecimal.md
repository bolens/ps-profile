# ConvertFrom-HexToDecimal

## Synopsis

Converts hexadecimal string to decimal representation.

## Description

Converts a hexadecimal string to decimal string representation.

## Signature

```powershell
ConvertFrom-HexToDecimal
```

## Parameters

### -InputObject

The hexadecimal string to convert. Can be piped.

### -Separator

Optional separator between decimal values. Default is a space.


## Outputs

System.String The decimal representation of the input hex string.


## Examples

### Example 1

```powershell
"4865" | ConvertFrom-HexToDecimal
```

Converts hex to decimal.

## Aliases

This function has the following aliases:

- `hex-to-decimal` - Converts hexadecimal string to decimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/hex.ps1
