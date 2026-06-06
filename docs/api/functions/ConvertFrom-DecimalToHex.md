# ConvertFrom-DecimalToHex

## Synopsis

Converts decimal string to hexadecimal representation.

## Description

Converts a decimal string to hexadecimal string representation.

## Signature

```powershell
ConvertFrom-DecimalToHex
```

## Parameters

### -InputObject

The decimal string to convert. Can be piped.


## Outputs

System.String The hexadecimal representation of the input decimal string.


## Examples

### Example 1

`powershell
"72 105" | ConvertFrom-DecimalToHex
    Converts decimal to hex.
``

## Aliases

This function has the following aliases:

- `decimal-to-hex` - Converts decimal string to hexadecimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
