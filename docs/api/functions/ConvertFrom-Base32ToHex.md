# ConvertFrom-Base32ToHex

## Synopsis

Converts Base32 string to hexadecimal representation.

## Description

Converts a Base32 string to hexadecimal string representation.

## Signature

```powershell
ConvertFrom-Base32ToHex
```

## Parameters

### -InputObject

The Base32 string to convert. Can be piped.


## Outputs

System.String The hexadecimal representation of the input Base32 string.


## Examples

### Example 1

```powershell
"JBSWY3DP" | ConvertFrom-Base32ToHex
```

Converts Base32 to hex.

## Aliases

This function has the following aliases:

- `base32-to-hex` - Converts Base32 string to hexadecimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base32.ps1
