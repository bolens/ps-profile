# ConvertFrom-Base85ToHex

## Synopsis

Converts Base85 encoding to hexadecimal string.

## Description

Decodes Base85 encoded string to hexadecimal format.

## Signature

```powershell
ConvertFrom-Base85ToHex
```

## Parameters

### -InputObject

The Base85 encoded string to decode.


## Outputs

System.String Returns the hexadecimal string.


## Examples

### Example 1

`powershell
"87cURD]j7BEbo7" | ConvertFrom-Base85ToHex
    
    Converts Base85 to hex format.
``

## Aliases

This function has the following aliases:

- `base85-to-hex` - Converts Base85 encoding to hexadecimal string.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base85.ps1
