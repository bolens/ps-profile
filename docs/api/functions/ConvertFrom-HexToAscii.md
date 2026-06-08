# ConvertFrom-HexToAscii

## Synopsis

Converts hexadecimal string to ASCII text.

## Description

Converts a hexadecimal string back to ASCII text. The hex string should contain pairs of hex digits representing UTF-8 bytes.

## Signature

```powershell
ConvertFrom-HexToAscii
```

## Parameters

### -InputObject

The hexadecimal string to convert. Can be piped. Spaces and separators are automatically removed.


## Outputs

System.String The ASCII text representation of the input hex string.


## Examples

### Example 1

```powershell
"48656C6C6F" | ConvertFrom-HexToAscii
```

Converts "48656C6C6F" to "Hello".

### Example 2

```powershell
ConvertFrom-HexToAscii -InputObject "48 65 6C 6C 6F"
```

Converts hex with spaces to "Hello".

## Aliases

This function has the following aliases:

- `hex-to-ascii` - Converts hexadecimal string to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/hex.ps1
