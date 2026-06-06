# ConvertFrom-ModHexToDecimal

## Synopsis

Converts ModHex string to decimal representation.

## Description

Converts a ModHex string to decimal string representation.

## Signature

```powershell
ConvertFrom-ModHexToDecimal
```

## Parameters

### -InputObject

The ModHex string to convert. Can be piped.

### -Separator

Optional separator between decimal values. Default is a space.


## Outputs

System.String The decimal representation of the input ModHex string.


## Examples

### Example 1

`powershell
"hkkllkkl" | ConvertFrom-ModHexToDecimal
    Converts ModHex to decimal.
``

## Aliases

This function has the following aliases:

- `modhex-to-decimal` - Converts ModHex string to decimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/modhex.ps1
