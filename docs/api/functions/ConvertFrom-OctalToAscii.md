# ConvertFrom-OctalToAscii

## Synopsis

Converts octal string to ASCII text.

## Description

Converts an octal string back to ASCII text. The octal string should contain 3-digit octal values representing UTF-8 bytes.

## Signature

```powershell
ConvertFrom-OctalToAscii
```

## Parameters

### -InputObject

The octal string to convert. Can be piped. Spaces are automatically removed.


## Outputs

System.String The ASCII text representation of the input octal string.


## Examples

### Example 1

```powershell
"110 151" | ConvertFrom-OctalToAscii
```

Converts octal to "Hi".

### Example 2

```powershell
ConvertFrom-OctalToAscii -InputObject "101102"
```

Converts octal without spaces to "AB".

## Aliases

This function has the following aliases:

- `octal-to-ascii` - Converts octal string to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/numeric.ps1
