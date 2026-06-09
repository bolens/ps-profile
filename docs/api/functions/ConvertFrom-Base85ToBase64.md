# ConvertFrom-Base85ToBase64

## Synopsis

Converts Base85 encoding to Base64 encoding.

## Description

Converts a Base85 encoded string to Base64 format.

## Signature

```powershell
ConvertFrom-Base85ToBase64
```

## Parameters

### -InputObject

The Base85 encoded string to convert.


## Outputs

System.String Returns the Base64 encoded string.


## Examples

### Example 1

```powershell
"87cURD]j7BEbo7" | ConvertFrom-Base85ToBase64
```

Converts Base85 to Base64 format.

## Aliases

This function has the following aliases:

- `base85-to-base64` - Converts Base85 encoding to Base64 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base85.ps1
