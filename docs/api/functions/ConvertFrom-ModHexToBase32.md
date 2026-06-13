# ConvertFrom-ModHexToBase32

## Synopsis

Converts ModHex string to Base32 representation.

## Description

Converts a ModHex string to Base32 string representation.

## Signature

```powershell
ConvertFrom-ModHexToBase32
```

## Parameters

### -InputObject

The ModHex string to convert. Can be piped. Spaces are automatically removed.


## Outputs

System.String The Base32 representation of the input ModHex string.


## Examples

### Example 1

```powershell
"hkkllkkl" | ConvertFrom-ModHexToBase32
```

Converts ModHex to Base32.

## Aliases

This function has the following aliases:

- `modhex-to-base32` - Converts ModHex string to Base32 representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/modhex.ps1
