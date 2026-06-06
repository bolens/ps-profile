# ConvertFrom-Base32ToOctal

## Synopsis

Converts Base32 string to octal representation.

## Description

Converts a Base32 string to octal string representation.

## Signature

```powershell
ConvertFrom-Base32ToOctal
```

## Parameters

### -InputObject

The Base32 string to convert. Can be piped.

### -Separator

Optional separator between octal bytes. Default is a space.


## Outputs

System.String The octal representation of the input Base32 string.


## Examples

### Example 1

`powershell
"JBSWY3DP" | ConvertFrom-Base32ToOctal
    Converts Base32 to octal.
``

## Aliases

This function has the following aliases:

- `base32-to-octal` - Converts Base32 string to octal representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base32.ps1
