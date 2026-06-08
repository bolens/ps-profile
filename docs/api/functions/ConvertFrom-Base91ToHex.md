# ConvertFrom-Base91ToHex

## Synopsis

Converts Base91 encoding to hexadecimal string.

## Description

Decodes Base91 encoded string to hexadecimal format.

## Signature

```powershell
ConvertFrom-Base91ToHex
```

## Parameters

### -InputObject

The Base91 encoded string to decode.


## Outputs

System.String Returns the hexadecimal string.


## Examples

### Example 1

```powershell
">OwJh>Io0Tv!8PE" | ConvertFrom-Base91ToHex
```

Converts Base91 to hex format.

## Aliases

This function has the following aliases:

- `base91-to-hex` - Converts Base91 encoding to hexadecimal string.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base91.ps1
