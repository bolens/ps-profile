# ConvertFrom-UrlToBase32

## Synopsis

Converts URL/percent encoded string to Base32 representation.

## Description

Converts a URL/percent encoded string to Base32 string representation.

## Signature

```powershell
ConvertFrom-UrlToBase32
```

## Parameters

### -InputObject

The URL/percent encoded string to convert. Can be piped.


## Outputs

System.String The Base32 representation of the input URL encoded string.


## Examples

### Example 1

`powershell
"Hello%20World" | ConvertFrom-UrlToBase32
    Converts URL encoding to Base32.
``

## Aliases

This function has the following aliases:

- `url-to-base32` - Converts URL/percent encoded string to Base32 representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/url.ps1
