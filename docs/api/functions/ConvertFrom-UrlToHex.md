# ConvertFrom-UrlToHex

## Synopsis

Converts URL/percent encoded string to hexadecimal representation.

## Description

Converts a URL/percent encoded string to hexadecimal string representation.

## Signature

```powershell
ConvertFrom-UrlToHex
```

## Parameters

### -InputObject

The URL/percent encoded string to convert. Can be piped.


## Outputs

System.String The hexadecimal representation of the input URL encoded string.


## Examples

### Example 1

```powershell
"Hello%20World" | ConvertFrom-UrlToHex
```

Converts URL encoding to hex.

## Aliases

This function has the following aliases:

- `url-to-hex` - Converts URL/percent encoded string to hexadecimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/url.ps1
