# ConvertFrom-PlainTextToRtf

## Synopsis

Converts Plain Text file to RTF.

## Description

Uses pandoc to convert a Plain Text file to RTF (Rich Text Format).

## Signature

```powershell
ConvertFrom-PlainTextToRtf
```

## Parameters

### -InputPath

Path to the input Plain Text file.

### -OutputPath

Path for the output RTF file. If not specified, uses input path with .rtf extension.

### -Encoding

Text encoding of the input file (default: UTF8).


## Examples

### Example 1

```powershell
ConvertFrom-PlainTextToRtf -InputPath "document.txt" -OutputPath "document.rtf"
```

## Aliases

This function has the following aliases:

- `text-to-rtf` - Converts Plain Text file to RTF.
- `txt-to-rtf` - Converts Plain Text file to RTF.


## Source

Defined in: ../profile.d/conversion-modules/document/document-office-plaintext.ps1
