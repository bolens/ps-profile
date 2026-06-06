# ConvertFrom-OctalToHex

## Synopsis

Converts octal string to hexadecimal representation.

## Description

Converts an octal string to hexadecimal string representation.

## Signature

```powershell
ConvertFrom-OctalToHex
```

## Parameters

### -InputObject

The octal string to convert. Can be piped.


## Outputs

System.String The hexadecimal representation of the input octal string.


## Examples

### Example 1

`powershell
"110 151" | ConvertFrom-OctalToHex
    Converts octal to hex.
``

## Aliases

This function has the following aliases:

- `octal-to-hex` - Converts octal string to hexadecimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
