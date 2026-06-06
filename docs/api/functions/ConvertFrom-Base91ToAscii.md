# ConvertFrom-Base91ToAscii

## Synopsis

Converts Base91 encoding to ASCII text.

## Description

Decodes Base91 encoded string back to ASCII/UTF-8 text.

## Signature

```powershell
ConvertFrom-Base91ToAscii
```

## Parameters

### -InputObject

The Base91 encoded string to decode.


## Outputs

System.String Returns the decoded ASCII text.


## Examples

### Example 1

`powershell
">OwJh>Io0Tv!8PE" | ConvertFrom-Base91ToAscii
    
    Converts Base91 to text.
``

## Aliases

This function has the following aliases:

- `base91-to-ascii` - Converts Base91 encoding to ASCII text.


## Source

Defined in: ../profile.d/conversion-modules/data/encoding/base91.ps1
