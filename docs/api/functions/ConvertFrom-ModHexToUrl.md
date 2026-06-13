# ConvertFrom-ModHexToUrl

## Synopsis

Converts ModHex string to URL/percent encoded representation.

## Description

Converts a ModHex string to URL/percent encoded string representation.

## Signature

```powershell
ConvertFrom-ModHexToUrl
```

## Parameters

### -InputObject

The ModHex string to convert. Can be piped. Spaces are automatically removed.


## Outputs

System.String The URL/percent encoded representation of the input ModHex string.


## Examples

### Example 1

```powershell
"hkkllkkl" | ConvertFrom-ModHexToUrl
```

Converts ModHex to URL encoding.

## Aliases

This function has the following aliases:

- `modhex-to-url` - Converts ModHex string to URL/percent encoded representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/modhex.ps1
