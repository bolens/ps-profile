# ConvertFrom-UrlToModHex

## Synopsis

Converts URL/percent encoded string to ModHex representation.

## Description

Converts a URL/percent encoded string to ModHex string representation.

## Signature

```powershell
ConvertFrom-UrlToModHex
```

## Parameters

### -InputObject

The URL/percent encoded string to convert. Can be piped.


## Outputs

System.String The ModHex representation of the input URL encoded string.


## Examples

### Example 1

`powershell
"Hello%20World" | ConvertFrom-UrlToModHex
    Converts URL encoding to ModHex.
``

## Aliases

This function has the following aliases:

- `url-to-modhex` - Converts URL/percent encoded string to ModHex representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/url.ps1
