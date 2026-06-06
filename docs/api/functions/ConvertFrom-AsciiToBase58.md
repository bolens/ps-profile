# ConvertFrom-AsciiToBase58

## Synopsis

Converts ASCII text to Base58 encoding.

## Description

Encodes ASCII/UTF-8 text to Base58 format. Base58 is commonly used by Bitcoin addresses and other cryptocurrency applications.

## Signature

```powershell
ConvertFrom-AsciiToBase58
```

## Parameters

### -InputObject

The text string to encode.


## Outputs

System.String Returns the Base58 encoded string.


## Examples

### Example 1

`powershell
"Hello World" | ConvertFrom-AsciiToBase58
    
    Converts text to Base58 format.
``

## Aliases

This function has the following aliases:

- `ascii-to-base58` - Converts ASCII text to Base58 encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base58.ps1
