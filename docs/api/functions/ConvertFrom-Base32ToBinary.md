# ConvertFrom-Base32ToBinary

## Synopsis

Converts Base32 string to binary representation.

## Description

Converts a Base32 string to binary string representation.

## Signature

```powershell
ConvertFrom-Base32ToBinary
```

## Parameters

### -InputObject

The Base32 string to convert. Can be piped.

### -Separator

Optional separator between binary bytes. Default is a space.


## Outputs

System.String The binary representation of the input Base32 string.


## Examples

### Example 1

```powershell
"JBSWY3DP" | ConvertFrom-Base32ToBinary
```

Converts Base32 to binary with spaces.

## Aliases

This function has the following aliases:

- `base32-to-binary` - Converts Base32 string to binary representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base32.ps1
