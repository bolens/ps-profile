# ConvertFrom-UrlToBinary

## Synopsis

Converts URL/percent encoded string to binary representation.

## Description

Converts a URL/percent encoded string to binary string representation.

## Signature

```powershell
ConvertFrom-UrlToBinary
```

## Parameters

### -InputObject

The URL/percent encoded string to convert. Can be piped.

### -Separator

Optional separator between binary bytes. Default is a space.


## Outputs

System.String The binary representation of the input URL encoded string.


## Examples

### Example 1

```powershell
"Hello%20World" | ConvertFrom-UrlToBinary
```

Converts URL encoding to binary with spaces.

## Aliases

This function has the following aliases:

- `url-to-binary` - Converts URL/percent encoded string to binary representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/url.ps1
