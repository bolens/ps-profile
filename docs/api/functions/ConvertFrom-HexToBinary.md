# ConvertFrom-HexToBinary

## Synopsis

Converts hexadecimal string to binary representation.

## Description

Converts a hexadecimal string to binary string representation. Each hex byte is converted to an 8-bit binary value.

## Signature

```powershell
ConvertFrom-HexToBinary
```

## Parameters

### -InputObject

The hexadecimal string to convert. Can be piped. Spaces and separators are automatically removed.

### -Separator

Optional separator between binary bytes. Default is a space.


## Outputs

System.String The binary representation of the input hex string.


## Examples

### Example 1

```powershell
"4865" | ConvertFrom-HexToBinary
```

Converts hex to binary with spaces.

### Example 2

```powershell
ConvertFrom-HexToBinary -InputObject "FF" -Separator ""
```

Converts hex to binary without separator.

## Aliases

This function has the following aliases:

- `hex-to-binary` - Converts hexadecimal string to binary representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/hex.ps1
