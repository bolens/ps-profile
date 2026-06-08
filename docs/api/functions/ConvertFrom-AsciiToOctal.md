# ConvertFrom-AsciiToOctal

## Synopsis

Converts ASCII text to octal representation.

## Description

Converts ASCII text to octal string representation. Each character is converted to its UTF-8 byte representation in octal (base 8).

## Signature

```powershell
ConvertFrom-AsciiToOctal
```

## Parameters

### -InputObject

The ASCII text to convert. Can be piped.

### -Separator

Optional separator between octal bytes. Default is a space.


## Outputs

System.String The octal representation of the input text.


## Examples

### Example 1

```powershell
"Hi" | ConvertFrom-AsciiToOctal
```

Converts "Hi" to "110 151" (octal representation).

### Example 2

```powershell
ConvertFrom-AsciiToOctal -InputObject "AB" -Separator ""
```

Converts "AB" to "101102" (no separator).

## Aliases

This function has the following aliases:

- `ascii-to-octal` - Converts ASCII text to octal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/ascii.ps1
