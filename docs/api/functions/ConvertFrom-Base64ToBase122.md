# ConvertFrom-Base64ToBase122

## Synopsis

Converts Base64 encoding to Base122 encoding.

## Description

Converts a Base64 encoded string to Base122 format.

## Signature

```powershell
ConvertFrom-Base64ToBase122
```

## Parameters

### -InputObject

The Base64 encoded string to convert.


## Outputs

System.String Returns the Base122 encoded string.


## Examples

### Example 1

```powershell
"SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase122
```

Converts Base64 to Base122 format.

## Aliases

This function has the following aliases:

- `base64-to-base122` - Converts Base64 encoding to Base122 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base122.ps1
