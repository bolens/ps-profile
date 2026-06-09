# ConvertFrom-EBCDICToAscii

## Synopsis

Converts EBCDIC encoding to ASCII text.

## Description

Decodes EBCDIC encoded string (as hexadecimal) back to ASCII text.

## Signature

```powershell
ConvertFrom-EBCDICToAscii
```

## Parameters

### -InputObject

The EBCDIC encoded string as hexadecimal.


## Outputs

System.String Returns the decoded ASCII text.


## Examples

### Example 1

```powershell
"C885939396" | ConvertFrom-EBCDICToAscii
```

Converts EBCDIC hex to text.

## Aliases

This function has the following aliases:

- `ebcdic-to-ascii` - Converts EBCDIC encoding to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/ebcdic.ps1
