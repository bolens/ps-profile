# ConvertTo-Base32

## Synopsis

Encodes text to Base32 format.

## Description

Encodes text to Base32 format. Requires Node.js and base32-encode package.

## Signature

```powershell
ConvertTo-Base32
```

## Parameters

### -Text

The text to encode. Can be piped.


## Outputs

System.String The Base32-encoded string.


## Examples

### Example 1

```powershell
"Hello" | ConvertTo-Base32
```

Encodes the text to Base32.

## Aliases

This function has the following aliases:

- `base32-encode` - Encodes text to Base32 format.


## Source

Defined in: ../profile.d/dev-tools-modules/encoding/base-encoding.ps1
