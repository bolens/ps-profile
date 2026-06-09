# ConvertFrom-AsciiToModHex

## Synopsis

Converts ASCII text to ModHex representation.

## Description

Converts ASCII text to ModHex (modified hexadecimal) string representation. ModHex is used by YubiKey and similar devices. Uses characters: c, b, d, e, f, g, h, i, j, k, l, n, r, t, u, v instead of 0-9, A-F.

## Signature

```powershell
ConvertFrom-AsciiToModHex
```

## Parameters

### -InputObject

The ASCII text to convert. Can be piped.


## Outputs

System.String The ModHex representation of the input text.


## Examples

### Example 1

```powershell
"Hello" | ConvertFrom-AsciiToModHex
```

Converts "Hello" to ModHex representation.

### Example 2

```powershell
ConvertFrom-AsciiToModHex -InputObject "Test"
```

Converts "Test" to ModHex representation.

## Aliases

This function has the following aliases:

- `ascii-to-modhex` - Converts ASCII text to ModHex representation.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/ascii.ps1
