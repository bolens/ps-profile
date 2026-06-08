# ConvertFrom-Base62ToHex

## Synopsis

Converts Base62 encoding to hexadecimal string.

## Description

Decodes Base62 encoded string to hexadecimal format.

## Signature

```powershell
ConvertFrom-Base62ToHex
```

## Parameters

### -InputObject

The Base62 encoded string to decode.


## Outputs

System.String Returns the hexadecimal string.


## Examples

### Example 1

```powershell
"73W9kKxE" | ConvertFrom-Base62ToHex
```

Converts Base62 to hex format.

## Aliases

This function has the following aliases:

- `base62-to-hex` - Converts Base62 encoding to hexadecimal string.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base62.ps1
