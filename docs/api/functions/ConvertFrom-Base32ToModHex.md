# ConvertFrom-Base32ToModHex

## Synopsis

Converts Base32 string to ModHex representation.

## Description

Converts a Base32 string to ModHex string representation.

## Signature

```powershell
ConvertFrom-Base32ToModHex
```

## Parameters

### -InputObject

The Base32 string to convert. Can be piped.


## Outputs

System.String The ModHex representation of the input Base32 string.


## Examples

### Example 1

`powershell
"JBSWY3DP" | ConvertFrom-Base32ToModHex
    Converts Base32 to ModHex.
``

## Aliases

This function has the following aliases:

- `base32-to-modhex` - Converts Base32 string to ModHex representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base32.ps1
