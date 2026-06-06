# ConvertFrom-DecimalToOctal

## Synopsis

Converts decimal string to octal representation.

## Description

Converts a decimal string to octal string representation.

## Signature

```powershell
ConvertFrom-DecimalToOctal
```

## Parameters

### -InputObject

The decimal string to convert. Can be piped.

### -Separator

Optional separator between octal bytes. Default is a space.


## Outputs

System.String The octal representation of the input decimal string.


## Examples

### Example 1

`powershell
"72 105" | ConvertFrom-DecimalToOctal
    Converts decimal to octal.
``

## Aliases

This function has the following aliases:

- `decimal-to-octal` - Converts decimal string to octal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
