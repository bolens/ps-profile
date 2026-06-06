# ConvertFrom-HexToOctal

## Synopsis

Converts hexadecimal string to octal representation.

## Description

Converts a hexadecimal string to octal string representation.

## Signature

```powershell
ConvertFrom-HexToOctal
```

## Parameters

### -InputObject

The hexadecimal string to convert. Can be piped.

### -Separator

Optional separator between octal bytes. Default is a space.


## Outputs

System.String The octal representation of the input hex string.


## Examples

### Example 1

`powershell
"4865" | ConvertFrom-HexToOctal
    Converts hex to octal.
``

## Aliases

This function has the following aliases:

- `hex-to-octal` - Converts hexadecimal string to octal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/hex.ps1
