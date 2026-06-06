# ConvertFrom-Base32ToDecimal

## Synopsis

Converts Base32 string to decimal representation.

## Description

Converts a Base32 string to decimal string representation.

## Signature

```powershell
ConvertFrom-Base32ToDecimal
```

## Parameters

### -InputObject

The Base32 string to convert. Can be piped.

### -Separator

Optional separator between decimal values. Default is a space.


## Outputs

System.String The decimal representation of the input Base32 string.


## Examples

### Example 1

`powershell
"JBSWY3DP" | ConvertFrom-Base32ToDecimal
    Converts Base32 to decimal.
``

## Aliases

This function has the following aliases:

- `base32-to-decimal` - Converts Base32 string to decimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base32.ps1
