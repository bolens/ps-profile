# ConvertFrom-OctalToBase32

## Synopsis

Converts octal string to Base32 representation.

## Description

Converts an octal string to Base32 string representation.

## Signature

```powershell
ConvertFrom-OctalToBase32
```

## Parameters

### -InputObject

The octal string to convert. Can be piped.


## Outputs

System.String The Base32 representation of the input octal string.


## Examples

### Example 1

`powershell
"110 151" | ConvertFrom-OctalToBase32
    Converts octal to Base32.
``

## Aliases

This function has the following aliases:

- `octal-to-base32` - Converts octal string to Base32 representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
