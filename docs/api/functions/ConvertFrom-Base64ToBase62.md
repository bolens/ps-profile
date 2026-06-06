# ConvertFrom-Base64ToBase62

## Synopsis

Converts Base64 encoding to Base62 encoding.

## Description

Converts a Base64 encoded string to Base62 format.

## Signature

```powershell
ConvertFrom-Base64ToBase62
```

## Parameters

### -InputObject

The Base64 encoded string to convert.


## Outputs

System.String Returns the Base62 encoded string.


## Examples

### Example 1

`powershell
"SGVsbG8gV29ybGQ=" | ConvertFrom-Base64ToBase62
    
    Converts Base64 to Base62 format.
``

## Aliases

This function has the following aliases:

- `base64-to-base62` - Converts Base64 encoding to Base62 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base62.ps1
