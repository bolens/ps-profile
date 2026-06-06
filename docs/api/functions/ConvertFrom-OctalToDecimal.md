# ConvertFrom-OctalToDecimal

## Synopsis

Converts octal string to decimal representation.

## Description

Converts an octal string to decimal string representation.

## Signature

```powershell
ConvertFrom-OctalToDecimal
```

## Parameters

### -InputObject

The octal string to convert. Can be piped.

### -Separator

Optional separator between decimal values. Default is a space.


## Outputs

System.String The decimal representation of the input octal string.


## Examples

### Example 1

`powershell
"110 151" | ConvertFrom-OctalToDecimal
    Converts octal to decimal.
``

## Aliases

This function has the following aliases:

- `octal-to-decimal` - Converts octal string to decimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
