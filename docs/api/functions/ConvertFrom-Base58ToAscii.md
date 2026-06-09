# ConvertFrom-Base58ToAscii

## Synopsis

Converts Base58 encoding to ASCII text.

## Description

Decodes Base58 encoded string back to ASCII/UTF-8 text.

## Signature

```powershell
ConvertFrom-Base58ToAscii
```

## Parameters

### -InputObject

The Base58 encoded string to decode.


## Outputs

System.String Returns the decoded ASCII text.


## Examples

### Example 1

```powershell
"JxF12TrwUP45BMd" | ConvertFrom-Base58ToAscii
```

Converts Base58 to text.

## Aliases

This function has the following aliases:

- `base58-to-ascii` - Converts Base58 encoding to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base58.ps1
