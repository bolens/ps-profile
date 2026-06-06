# ConvertFrom-AsciiToBase62

## Synopsis

Converts ASCII text to Base62 encoding.

## Description

Encodes ASCII/UTF-8 text to Base62 format. Base62 is a URL-safe alphanumeric encoding using 0-9, A-Z, and a-z.

## Signature

```powershell
ConvertFrom-AsciiToBase62
```

## Parameters

### -InputObject

The text string to encode.


## Outputs

System.String Returns the Base62 encoded string.


## Examples

### Example 1

`powershell
"Hello World" | ConvertFrom-AsciiToBase62
    
    Converts text to Base62 format.
``

## Aliases

This function has the following aliases:

- `ascii-to-base62` - Converts ASCII text to Base62 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base62.ps1
