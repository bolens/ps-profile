# ConvertFrom-ModHexToOctal

## Synopsis

Converts ModHex string to octal representation.

## Description

Converts a ModHex string to octal string representation.

## Signature

```powershell
ConvertFrom-ModHexToOctal
```

## Parameters

### -InputObject

The ModHex string to convert. Can be piped.

### -Separator

Optional separator between octal bytes. Default is a space.


## Outputs

System.String The octal representation of the input ModHex string.


## Examples

### Example 1

```powershell
"hkkllkkl" | ConvertFrom-ModHexToOctal
```

Converts ModHex to octal.

## Aliases

This function has the following aliases:

- `modhex-to-octal` - Converts ModHex string to octal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/modhex.ps1
