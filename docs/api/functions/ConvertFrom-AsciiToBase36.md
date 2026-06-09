# ConvertFrom-AsciiToBase36

## Synopsis

Converts ASCII text to Base36 encoding.

## Description

Encodes ASCII/UTF-8 text to Base36 format. Base36 is an alphanumeric encoding using 0-9 and A-Z.

## Signature

```powershell
ConvertFrom-AsciiToBase36
```

## Parameters

### -InputObject

The text string to encode.


## Outputs

System.String Returns the Base36 encoded string.


## Examples

### Example 1

```powershell
"Hello World" | ConvertFrom-AsciiToBase36
```

Converts text to Base36 format.

## Aliases

This function has the following aliases:

- `ascii-to-base36` - Converts ASCII text to Base36 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base36.ps1
