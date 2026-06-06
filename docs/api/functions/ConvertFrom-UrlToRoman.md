# ConvertFrom-UrlToRoman

## Synopsis

Converts URL/percent encoded string to Roman numeral representation.

## Description

Converts a URL/percent encoded string to Roman numeral string representation.

## Signature

```powershell
ConvertFrom-UrlToRoman
```

## Parameters

### -InputObject

The URL/percent encoded string to convert. Can be piped.

### -Separator

Optional separator between Roman numerals. Default is a space.


## Outputs

System.String The Roman numeral representation of the input URL encoded string.


## Examples

### Example 1

`powershell
"Hello%20World" | ConvertFrom-UrlToRoman
    Converts URL encoding to Roman numerals.
``

## Aliases

This function has the following aliases:

- `url-to-roman` - Converts URL/percent encoded string to Roman numeral representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/url.ps1
