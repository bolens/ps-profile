# ConvertFrom-AsciiToBase32

## Synopsis

Converts ASCII text to Base32 representation.

## Description

Converts ASCII text to Base32 string representation. Base32 uses the alphabet A-Z, 2-7 (32 characters) as defined in RFC 4648.

## Signature

```powershell
ConvertFrom-AsciiToBase32
```

## Parameters

### -InputObject

The ASCII text to convert. Can be piped.


## Outputs

System.String The Base32 representation of the input text.


## Examples

### Example 1

```powershell
"Hello" | ConvertFrom-AsciiToBase32
```

Converts "Hello" to Base32 representation.

### Example 2

```powershell
ConvertFrom-AsciiToBase32 -InputObject "World"
```

Converts "World" to Base32 representation.

## Aliases

This function has the following aliases:

- `ascii-to-base32` - Converts ASCII text to Base32 representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/ascii.ps1
