# ConvertFrom-DecimalToBase32

## Synopsis

Converts decimal string to Base32 representation.

## Description

Converts a decimal string to Base32 string representation.

## Signature

```powershell
ConvertFrom-DecimalToBase32
```

## Parameters

### -InputObject

The decimal string to convert. Can be piped.


## Outputs

System.String The Base32 representation of the input decimal string.


## Examples

### Example 1

`powershell
"72 105" | ConvertFrom-DecimalToBase32
    Converts decimal to Base32.
``

## Aliases

This function has the following aliases:

- `decimal-to-base32` - Converts decimal string to Base32 representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
