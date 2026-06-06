# ConvertFrom-Base32ToAscii

## Synopsis

Converts Base32 string to ASCII text.

## Description

Converts a Base32 string back to ASCII text. Base32 uses the alphabet A-Z, 2-7 (32 characters).

## Signature

```powershell
ConvertFrom-Base32ToAscii
```

## Parameters

### -InputObject

The Base32 string to convert. Can be piped. Padding characters (=) are automatically handled.


## Outputs

System.String The ASCII text representation of the input Base32 string.


## Examples

### Example 1

`powershell
"JBSWY3DP" | ConvertFrom-Base32ToAscii
    Converts Base32 to "Hello".
``

### Example 2

`powershell
ConvertFrom-Base32ToAscii -InputObject "MZXW6YTBOI======"
    Converts Base32 string to ASCII.
``

## Aliases

This function has the following aliases:

- `base32-to-ascii` - Converts Base32 string to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base32.ps1
