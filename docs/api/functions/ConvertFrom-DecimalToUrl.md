# ConvertFrom-DecimalToUrl

## Synopsis

Converts decimal string to URL/percent encoding representation.

## Description

Converts a decimal string to URL/percent encoding representation.

## Signature

```powershell
ConvertFrom-DecimalToUrl
```

## Parameters

### -InputObject

The decimal string to convert. Can be piped.


## Outputs

System.String The URL/percent encoded representation of the input decimal string.


## Examples

### Example 1

`powershell
"72 105" | ConvertFrom-DecimalToUrl
    Converts decimal to URL encoding.
``

## Aliases

This function has the following aliases:

- `decimal-to-url` - Converts decimal string to URL/percent encoding representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
