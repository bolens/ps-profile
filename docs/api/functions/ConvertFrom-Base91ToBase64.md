# ConvertFrom-Base91ToBase64

## Synopsis

Converts Base91 encoding to Base64 encoding.

## Description

Converts a Base91 encoded string to Base64 format.

## Signature

```powershell
ConvertFrom-Base91ToBase64
```

## Parameters

### -InputObject

The Base91 encoded string to convert.


## Outputs

System.String Returns the Base64 encoded string.


## Examples

### Example 1

`powershell
">OwJh>Io0Tv!8PE" | ConvertFrom-Base91ToBase64
    
    Converts Base91 to Base64 format.
``

## Aliases

This function has the following aliases:

- `base91-to-base64` - Converts Base91 encoding to Base64 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base91.ps1
