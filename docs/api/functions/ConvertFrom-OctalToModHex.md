# ConvertFrom-OctalToModHex

## Synopsis

Converts octal string to ModHex representation.

## Description

Converts an octal string to ModHex string representation.

## Signature

```powershell
ConvertFrom-OctalToModHex
```

## Parameters

### -InputObject

The octal string to convert. Can be piped.


## Outputs

System.String The ModHex representation of the input octal string.


## Examples

### Example 1

`powershell
"110 151" | ConvertFrom-OctalToModHex
    Converts octal to ModHex.
``

## Aliases

This function has the following aliases:

- `octal-to-modhex` - Converts octal string to ModHex representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
