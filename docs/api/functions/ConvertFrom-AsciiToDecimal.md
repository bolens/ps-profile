# ConvertFrom-AsciiToDecimal

## Synopsis

Converts ASCII text to decimal representation.

## Description

Converts ASCII text to decimal string representation. Each character is converted to its UTF-8 byte value in decimal.

## Signature

```powershell
ConvertFrom-AsciiToDecimal
```

## Parameters

### -InputObject

The ASCII text to convert. Can be piped.

### -Separator

Optional separator between decimal values. Default is a space.


## Outputs

System.String The decimal representation of the input text.


## Examples

### Example 1

```powershell
"Hi" | ConvertFrom-AsciiToDecimal
```

Converts "Hi" to "72 105" (decimal representation).

### Example 2

```powershell
ConvertFrom-AsciiToDecimal -InputObject "AB" -Separator ","
```

Converts "AB" to "65,66" (comma separator).

## Aliases

This function has the following aliases:

- `ascii-to-decimal` - Converts ASCII text to decimal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/ascii.ps1
