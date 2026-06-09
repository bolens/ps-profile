# ConvertFrom-UrlToOctal

## Synopsis

Converts URL/percent encoded string to octal representation.

## Description

Converts a URL/percent encoded string to octal string representation.

## Signature

```powershell
ConvertFrom-UrlToOctal
```

## Parameters

### -InputObject

The URL/percent encoded string to convert. Can be piped.

### -Separator

Optional separator between octal bytes. Default is a space.


## Outputs

System.String The octal representation of the input URL encoded string.


## Examples

### Example 1

```powershell
"Hello%20World" | ConvertFrom-UrlToOctal
```

Converts URL encoding to octal.

## Aliases

This function has the following aliases:

- `url-to-octal` - Converts URL/percent encoded string to octal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/url.ps1
