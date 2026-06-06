# ConvertFrom-Base62ToBase64

## Synopsis

Converts Base62 encoding to Base64 encoding.

## Description

Converts a Base62 encoded string to Base64 format.

## Signature

```powershell
ConvertFrom-Base62ToBase64
```

## Parameters

### -InputObject

The Base62 encoded string to convert.


## Outputs

System.String Returns the Base64 encoded string.


## Examples

### Example 1

`powershell
"73W9kKxE" | ConvertFrom-Base62ToBase64
    
    Converts Base62 to Base64 format.
``

## Aliases

This function has the following aliases:

- `base62-to-base64` - Converts Base62 encoding to Base64 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base62.ps1
