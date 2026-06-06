# ConvertFrom-OctalToUrl

## Synopsis

Converts octal string to URL/percent encoded representation.

## Description

Converts an octal string to URL/percent encoded string representation.

## Signature

```powershell
ConvertFrom-OctalToUrl
```

## Parameters

### -InputObject

The octal string to convert. Can be piped.


## Outputs

System.String The URL/percent encoded representation of the input octal string.


## Examples

### Example 1

`powershell
"110 151" | ConvertFrom-OctalToUrl
    Converts octal to URL encoding.
``

## Aliases

This function has the following aliases:

- `octal-to-url` - Converts octal string to URL/percent encoded representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
