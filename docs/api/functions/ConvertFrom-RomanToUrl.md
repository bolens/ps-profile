# ConvertFrom-RomanToUrl

## Synopsis

Converts Roman numeral string to URL/percent encoded representation.

## Description

Converts a Roman numeral string to URL/percent encoded string representation.

## Signature

```powershell
ConvertFrom-RomanToUrl
```

## Parameters

### -InputObject

The Roman numeral string to convert. Can be piped.


## Outputs

System.String The URL/percent encoded representation of the input Roman numeral string.


## Examples

### Example 1

`powershell
"LXXII CV" | ConvertFrom-RomanToUrl
    Converts Roman numerals to URL encoding.
``

## Aliases

This function has the following aliases:

- `roman-to-url` - Converts Roman numeral string to URL/percent encoded representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/roman.ps1
