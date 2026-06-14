# ConvertFrom-UrlToAscii

## Synopsis

Converts URL/percent encoded string to ASCII text.

## Description

Converts a URL/percent encoded string back to ASCII text. %XX sequences are decoded to their character equivalents.

## Signature

```powershell
ConvertFrom-UrlToAscii
```

## Parameters

### -InputObject

The URL/percent encoded string to convert. Can be piped.


## Outputs

System.String The ASCII text representation of the input URL encoded string.


## Examples

### Example 1

```powershell
"Hello%20World" | ConvertFrom-UrlToAscii
```

Converts "Hello%20World" to "Hello World".

### Example 2

```powershell
ConvertFrom-UrlToAscii -InputObject "test%40example.com"
```

Converts URL encoding to "test@example.com".

## Aliases

This function has the following aliases:

- `url-to-ascii` - Converts URL/percent encoded string to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/url.ps1
