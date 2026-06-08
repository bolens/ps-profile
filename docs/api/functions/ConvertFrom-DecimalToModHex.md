# ConvertFrom-DecimalToModHex

## Synopsis

Converts decimal string to ModHex representation.

## Description

Converts a decimal string to ModHex string representation.

## Signature

```powershell
ConvertFrom-DecimalToModHex
```

## Parameters

### -InputObject

The decimal string to convert. Can be piped.


## Outputs

System.String The ModHex representation of the input decimal string.


## Examples

### Example 1

```powershell
"72 105" | ConvertFrom-DecimalToModHex
```

Converts decimal to ModHex.

## Aliases

This function has the following aliases:

- `decimal-to-modhex` - Converts decimal string to ModHex representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
