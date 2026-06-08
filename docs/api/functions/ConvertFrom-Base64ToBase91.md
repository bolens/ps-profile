# ConvertFrom-Base64ToBase91

## Synopsis

Converts Base64 encoding to Base91 encoding.

## Description

Converts a Base64 encoded string to Base91 format.

## Signature

```powershell
ConvertFrom-Base64ToBase91
```

## Parameters

### -InputObject

The Base64 encoded string to convert.


## Outputs

System.String Returns the Base91 encoded string.


## Examples

### Example 1

```powershell
"SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase91
```

Converts Base64 to Base91 format.

## Aliases

This function has the following aliases:

- `base64-to-base91` - Converts Base64 encoding to Base91 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base91.ps1
