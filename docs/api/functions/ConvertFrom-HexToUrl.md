# ConvertFrom-HexToUrl

## Synopsis

Converts hexadecimal string to URL/percent encoded representation.

## Description

Converts a hexadecimal string to URL/percent encoded string representation.

## Signature

```powershell
ConvertFrom-HexToUrl
```

## Parameters

### -InputObject

The hexadecimal string to convert. Can be piped. Spaces and separators are automatically removed.


## Outputs

System.String The URL/percent encoded representation of the input hex string.


## Examples

### Example 1

`powershell
"48656C6C6F" | ConvertFrom-HexToUrl
    Converts hex to URL encoding.
``

## Aliases

This function has the following aliases:

- `hex-to-url` - Converts hexadecimal string to URL/percent encoded representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/hex.ps1
