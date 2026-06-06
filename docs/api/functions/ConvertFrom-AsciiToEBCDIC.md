# ConvertFrom-AsciiToEBCDIC

## Synopsis

Converts ASCII text to EBCDIC encoding.

## Description

Encodes ASCII text to EBCDIC format (Code Page 037). Returns the EBCDIC encoding as a hexadecimal string.

## Signature

```powershell
ConvertFrom-AsciiToEBCDIC
```

## Parameters

### -InputObject

The text string to encode.


## Outputs

System.String Returns the EBCDIC encoded string as hexadecimal.


## Examples

### Example 1

`powershell
"Hello" | ConvertFrom-AsciiToEBCDIC
    
    Converts text to EBCDIC format (returns hex string).
``

## Aliases

This function has the following aliases:

- `ascii-to-ebcdic` - Converts ASCII text to EBCDIC encoding.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/ebcdic.ps1
