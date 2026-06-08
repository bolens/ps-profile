# ConvertFrom-Base32

## Synopsis

Decodes Base32-encoded text.

## Description

Decodes Base32-encoded text back to original form. Requires Node.js and base32-decode package.

## Signature

```powershell
ConvertFrom-Base32
```

## Parameters

### -Text

The Base32-encoded text to decode. Can be piped.


## Outputs

System.String The decoded string.


## Examples

### Example 1

```powershell
"JBSWY3DP" | ConvertFrom-Base32
```

Decodes the Base32 string.

## Aliases

This function has the following aliases:

- `base32-decode` - Decodes Base32-encoded text.


## Source

Defined in: ../profile.d/dev-tools-modules/encoding/base-encoding.ps1
