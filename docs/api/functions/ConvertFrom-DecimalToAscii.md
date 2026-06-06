# ConvertFrom-DecimalToAscii

## Synopsis

Converts decimal string to ASCII text.

## Description

Converts a decimal string back to ASCII text. The decimal string should contain decimal values (0-255) representing UTF-8 bytes.

## Signature

```powershell
ConvertFrom-DecimalToAscii
```

## Parameters

### -InputObject

The decimal string to convert. Can be piped. Values can be separated by spaces or commas.


## Outputs

System.String The ASCII text representation of the input decimal string.


## Examples

### Example 1

`powershell
"72 105" | ConvertFrom-DecimalToAscii
    Converts decimal to "Hi".
``

### Example 2

`powershell
ConvertFrom-DecimalToAscii -InputObject "65,66"
    Converts decimal with commas to "AB".
``

## Aliases

This function has the following aliases:

- `decimal-to-ascii` - Converts decimal string to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
