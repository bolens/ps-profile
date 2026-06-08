# ConvertFrom-Rot13ToAscii

## Synopsis

Converts ROT13 cipher encoding to ASCII text.

## Description

Decodes ROT13 encoded string back to ASCII text. Since ROT13 is self-inverse, this is the same as encoding.

## Signature

```powershell
ConvertFrom-Rot13ToAscii
```

## Parameters

### -InputObject

The ROT13 encoded string to decode.


## Outputs

System.String Returns the decoded ASCII text.


## Examples

### Example 1

```powershell
"Uryyb Jbeyq" | ConvertFrom-Rot13ToAscii
```

Converts ROT13 to text.

## Aliases

This function has the following aliases:

- `rot13-to-ascii` - Converts ROT13 cipher encoding to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/rot.ps1
