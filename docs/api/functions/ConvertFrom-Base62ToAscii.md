# ConvertFrom-Base62ToAscii

## Synopsis

Converts Base62 encoding to ASCII text.

## Description

Decodes Base62 encoded string back to ASCII/UTF-8 text.

## Signature

```powershell
ConvertFrom-Base62ToAscii
```

## Parameters

### -InputObject

The Base62 encoded string to decode.


## Outputs

System.String Returns the decoded ASCII text.


## Examples

### Example 1

`powershell
"73W9kKxE" | ConvertFrom-Base62ToAscii
    
    Converts Base62 to text.
``

## Aliases

This function has the following aliases:

- `base62-to-ascii` - Converts Base62 encoding to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base62.ps1
