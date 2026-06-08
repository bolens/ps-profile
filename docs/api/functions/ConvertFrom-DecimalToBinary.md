# ConvertFrom-DecimalToBinary

## Synopsis

Converts decimal string to binary representation.

## Description

Converts a decimal string to binary string representation.

## Signature

```powershell
ConvertFrom-DecimalToBinary
```

## Parameters

### -InputObject

The decimal string to convert. Can be piped.

### -Separator

Optional separator between binary bytes. Default is a space.


## Outputs

System.String The binary representation of the input decimal string.


## Examples

### Example 1

```powershell
"72 105" | ConvertFrom-DecimalToBinary
```

Converts decimal to binary.

## Aliases

This function has the following aliases:

- `decimal-to-binary` - Converts decimal string to binary representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
