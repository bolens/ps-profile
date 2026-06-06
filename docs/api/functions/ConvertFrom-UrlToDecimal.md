# ConvertFrom-UrlToDecimal

## Synopsis

Converts URL/percent encoded string to decimal representation.

## Description

Converts a URL/percent encoded string to decimal string representation.

## Signature

```powershell
ConvertFrom-UrlToDecimal
```

## Parameters

### -InputObject

The URL/percent encoded string to convert. Can be piped.

### -Separator

Optional separator between decimal values. Default is a space.


## Outputs

System.String The decimal representation of the input URL encoded string.


## Examples

### Example 1

`powershell
"Hello%20World" | ConvertFrom-UrlToDecimal
    Converts URL encoding to decimal.
``

## Aliases

This function has the following aliases:

- `url-to-decimal` - Converts URL/percent encoded string to decimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/url.ps1
