# ConvertFrom-HexToBase62

## Synopsis

Converts hexadecimal string to Base62 encoding.

## Description

Encodes a hexadecimal string to Base62 format.

## Signature

```powershell
ConvertFrom-HexToBase62
```

## Parameters

### -InputObject

The hexadecimal string to encode.


## Outputs

System.String Returns the Base62 encoded string.


## Examples

### Example 1

```powershell
"48656C6C6F" | ConvertFrom-HexToBase62
```

Converts hex to Base62 format.

## Aliases

This function has the following aliases:

- `hex-to-base62` - Converts hexadecimal string to Base62 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base62.ps1
