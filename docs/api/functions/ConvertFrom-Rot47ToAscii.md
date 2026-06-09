# ConvertFrom-Rot47ToAscii

## Synopsis

Converts ROT47 cipher encoding to ASCII text.

## Description

Decodes ROT47 encoded string back to ASCII text. Since ROT47 is self-inverse, this is the same as encoding.

## Signature

```powershell
ConvertFrom-Rot47ToAscii
```

## Parameters

### -InputObject

The ROT47 encoded string to decode.


## Outputs

System.String Returns the decoded ASCII text.


## Examples

### Example 1

```powershell
"w6==@ (@C=5P" | ConvertFrom-Rot47ToAscii
```

Converts ROT47 to text.

## Aliases

This function has the following aliases:

- `rot47-to-ascii` - Converts ROT47 cipher encoding to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/rot.ps1
